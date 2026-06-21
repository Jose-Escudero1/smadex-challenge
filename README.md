# FeatureFlagsKit

FeatureFlagsKit es un SDK de iOS, escrito en Swift y sin dependencias de terceros, que sirve para gestionar feature flags (interruptores de funcionalidad) tanto remotos como locales. Está pensado para integrarse en cualquier aplicación de iOS y leer valores de configuración de forma segura, ordenada y fácil de probar.

La idea de fondo es sencilla: la aplicación le pide un valor al SDK (por ejemplo, "¿está activada la nueva home?"), y el SDK responde con el valor más fiable que tenga en ese momento. Si ha podido hablar con el servidor, devuelve el valor remoto; si no, recurre a un valor por defecto que la propia aplicación ha definido. Así, la app nunca se queda sin respuesta.

Está escrito en Swift 6 y usa la concurrencia moderna del lenguaje (`actor` y `async/await`) para garantizar que el acceso a los datos compartidos sea seguro entre hilos.

## Qué resuelve

El framework permite:

- Definir feature flags con un tipo concreto (booleano, entero, decimal, texto o, opcionalmente, cualquier valor codificable en JSON).
- Leer el valor actual de un flag a través de una API limpia.
- Cargar los flags desde una fuente remota (simulada o real, según quien la implemente).
- Recurrir a valores por defecto locales cuando la red falla o falta un flag.
- Guardar en caché los valores remotos para que estén disponibles de inmediato, incluso entre arranques de la aplicación.

## Cómo integrarlo

El SDK se puede entregar y consumir de tres formas. Todas usan el mismo código.

### Como framework dentro del proyecto Xcode

El proyecto `FeatureFlagsKit.xcodeproj` contiene tres objetivos (targets): el framework `FeatureFlagsKit`, sus pruebas, y la aplicación de demostración `FeatureFlagsDemo`. Para usar el framework en otra aplicación, basta con arrastrar el proyecto a tu espacio de trabajo, añadir `FeatureFlagsKit.framework` en la sección de frameworks embebidos de tu app, y escribir `import FeatureFlagsKit`.

### Como XCFramework (binario)

En la raíz del repositorio hay un script que genera un `.xcframework` distribuible:

```
./build-xcframework.sh
```

El resultado se deja en `build/FeatureFlagsKit.xcframework` e incluye las versiones para dispositivo y para simulador. Una vez generado, se arrastra al proyecto de destino y se embebe como cualquier framework binario.

### Como paquete de Swift (SPM)

En la carpeta `FeatureFlagsKitPackage` hay una versión del SDK lista para Swift Package Manager. Se compila y se prueba con:

```
cd FeatureFlagsKitPackage
swift build
swift test
```

Para usarla desde otra aplicación se añade como dependencia, ya sea desde un repositorio remoto o desde una ruta local:

```swift
.package(url: "https://github.com/<tu-usuario>/FeatureFlagsKit.git", from: "1.0.0")
.package(path: "../FeatureFlagsKitPackage")
```

En un proyecto de Xcode también se puede añadir desde el menú "File, Add Package Dependencies, Add Local".

## La API pública

Primero se crea el cliente, indicándole de dónde sacar los datos remotos y qué valores usar por defecto:

```swift
let client = FeatureFlagsClient(
    remoteProvider: provider,
    localDefaults: [
        "new_home_enabled": .bool(false),
        "home_max_items": .int(20)
    ]
)
```

Para traer los valores del servidor y guardarlos en caché, se sincroniza:

```swift
try await client.refresh()
```

A partir de ahí se leen los flags. Hay una forma sencilla, indicando la clave como texto:

```swift
let isEnabled = await client.boolValue(for: "new_home_enabled")
let maxItems  = await client.intValue(for: "home_max_items")
let title     = await client.stringValue(for: "home_title")
```

Y una forma más segura, en la que las claves se definen una sola vez y el compilador ayuda a no equivocarse:

```swift
enum AppFlag: String, FeatureFlagKey {
    case newHomeEnabled = "new_home_enabled"
    case homeMaxItems   = "home_max_items"
    case homeTitle      = "home_title"
}

let enabled = await client.value(for: AppFlag.newHomeEnabled, as: Bool.self)
```

Las lecturas y la sincronización son asíncronas (llevan `await`) porque el cliente protege su estado interno mediante un `actor`. Esto se explica más abajo.

### Tipos soportados

El SDK admite valores booleanos, enteros, decimales y de texto. Además, como extra, admite cualquier valor que sea `Codable`, guardándolo internamente como JSON. Esto permite tener flags más ricos, por ejemplo un objeto con varios campos de configuración.

### El proveedor remoto

El SDK no decide de dónde vienen los datos. Eso lo decide quien lo use, implementando este protocolo:

```swift
public protocol FeatureFlagsRemoteProvider: Sendable {
    func fetchFlags(
        completion: @escaping @Sendable (Result<[String: FeatureFlagValue], Error>) -> Void
    )
}
```

La fuente puede ser una petición de red real con `URLSession`, un fichero JSON, un mock para pruebas o cualquier otra cosa. La aplicación de demostración incluye un proveedor falso que devuelve un JSON tras una pequeña espera, imitando una llamada de red.

## Cómo está organizado por dentro

El código se reparte en capas bien separadas, y solo una parte pequeña es visible desde fuera.

La capa pública es la única que conoce la aplicación. La forman el cliente (`FeatureFlagsClient`), el tipo que representa un valor (`FeatureFlagValue`), los protocolos de clave y de proveedor, y el tipo de error. Todo lo demás queda oculto.

La capa de dominio contiene el repositorio (`FlagRepository`), que reúne tres responsabilidades: resolver qué valor devolver, pedir los datos al proveedor remoto y guardarlos. Es una pieza interna y sin estado.

La capa de almacenamiento guarda la caché en disco (en `UserDefaults`) serializándola como JSON. Está detrás de un protocolo interno, de modo que en las pruebas se puede sustituir por una versión en memoria, sin tocar el disco real.

Esta separación, junto con el uso de protocolos en cada frontera, hace que el SDK sea fácil de probar y de mantener, y mantiene la superficie pública pequeña y estable.

## Cómo decide qué valor devolver

Cada vez que se pide un flag, el SDK busca el valor en tres sitios, por orden de prioridad, y devuelve el primero que encuentra:

1. Un override local de depuración, si se ha fijado uno.
2. El valor remoto guardado en caché.
3. El valor por defecto local que definió la aplicación.

Gracias a este orden, la lectura siempre tiene una respuesta razonable, incluso si nunca se ha sincronizado con el servidor o si la sincronización ha fallado.

## Concurrencia y seguridad de hilos

El estado que cambia con el tiempo (la caché en memoria y los overrides) vive dentro del cliente, que es un `actor`. Un actor atiende las peticiones de una en una, aunque lleguen desde muchos hilos a la vez. El propio compilador de Swift 6 garantiza que no se pueda acceder a ese estado de forma concurrente, lo que elimina por construcción las condiciones de carrera.

El precio de esta garantía es que las lecturas y la sincronización son asíncronas: hay que usar `await`. A cambio, no hace falta gestionar bloqueos manuales ni colas, y no hay riesgo de olvidar proteger un acceso.

El proveedor remoto funciona con un callback tradicional. El SDK lo adapta internamente al modelo `async/await` para integrarlo de forma limpia con el actor.

## La caché y el comportamiento ante fallos

Cuando una sincronización tiene éxito, los valores se guardan tanto en memoria como en disco. Por eso, al volver a abrir la aplicación, ya hay valores válidos disponibles desde el primer momento, sin necesidad de esperar a la red.

Si una sincronización falla, el SDK lanza un error pero no toca la caché anterior. Las lecturas siguen devolviendo el último valor bueno que se conocía o, si no había ninguno, el valor por defecto local. Es decir, un fallo de red nunca deja a la aplicación sin datos.

## Las pruebas

El SDK incluye una batería de pruebas unitarias que no dependen de la red ni del disco reales, gracias a los protocolos internos y a unos dobles de prueba ligeros. Cubren los siguientes escenarios:

- El fallback a los valores por defecto cuando no se ha sincronizado.
- La lectura de claves inexistentes, que devuelven el valor por defecto del tipo.
- El flujo de sincronización, que actualiza la caché con los valores remotos.
- El manejo de un fallo remoto, que lanza error pero conserva el fallback.
- La conservación de la caché válida cuando una sincronización posterior falla.
- El manejo de tipos que no coinciden, que también cae al valor por defecto del tipo.
- La persistencia de la caché entre distintas instancias del cliente.
- La lectura de valores codificables (Codable).
- La API segura con claves fuertemente tipadas.
- Los overrides de depuración.
- Un escenario de concurrencia con muchas lecturas y sincronizaciones simultáneas.

## La aplicación de demostración

La demo está hecha en SwiftUI y consume el framework. Muestra tres flags: uno booleano (`new_home_enabled`), uno de texto (`home_title`) y uno numérico (`home_max_items`), cada uno con su nombre.

Incluye un botón "Crear petición" que abre una ventana con un campo de texto. Ahí se puede pegar un JSON de flags, que el SDK aplica como si fuera la respuesta del servidor: pasa por el flujo real (proveedor, sincronización, caché) y la vista se actualiza con los nuevos valores. Si el JSON no es válido, se muestra el estado de error. Mientras se aplica, se muestra el estado de carga.

## Decisiones de diseño

Se eligió un `actor` en lugar de bloqueos manuales o colas de GCD porque la seguridad de hilos queda garantizada por el compilador, sin posibilidad de olvidar proteger un acceso.

Se mantuvo la superficie pública al mínimo: el dominio, el repositorio y el almacenamiento son internos, de modo que la aplicación solo ve lo que necesita.

Se modeló el valor de un flag como un tipo cerrado e inmutable, que además se puede guardar en disco de forma estable. Y se decidió que un fallo de sincronización nunca destruya la caché válida que ya se tenía.

## Compromisos

Usar un actor hace que las lecturas sean asíncronas, lo que se aparta del ejemplo síncrono del enunciado. Se aceptó ese cambio a cambio de la seguridad de hilos garantizada por el compilador.

La persistencia se hace con `UserDefaults`, que es simple y suficiente para flags, pero no sería lo adecuado para grandes volúmenes de datos.

La caché no caduca por tiempo: una vez guardada, se mantiene hasta la siguiente sincronización.

Cuando se pide un flag con un tipo que no coincide, el SDK devuelve el valor por defecto de ese tipo en lugar de lanzar un error, priorizando la robustez en tiempo de ejecución.

