# ``FeatureFlagsKit``

SDK ligero y seguro para hilos que gestiona feature flags remotos y locales con una API pública mínima y type-safe.

## Overview

`FeatureFlagsKit` permite definir flags fuertemente tipados, leerlos a través de una API limpia, sincronizarlos desde una fuente remota simulada y recurrir a valores por defecto locales (fallback) cuando la red falla o falta un flag.

El núcleo es ``FeatureFlagsClient``, un `actor` que aísla todo el estado mutable compartido (la caché remota en memoria y los overrides de debug), eliminando por construcción las condiciones de carrera.

```swift
let client = FeatureFlagsClient(
    remoteProvider: provider,
    localDefaults: [
        "new_home_enabled": .bool(false),
        "home_max_items": .int(20)
    ]
)

try await client.refresh()
let isEnabled = await client.boolValue(for: "new_home_enabled")
```

### Orden de resolución

Para cada clave, el valor se resuelve con la prioridad: **override de debug → caché remota → valor por defecto local**.

## Topics

### Cliente

- ``FeatureFlagsClient``

### Modelo de datos

- ``FeatureFlagValue``
- ``FeatureFlagKey``

### Fuente remota

- ``FeatureFlagsRemoteProvider``

### Errores

- ``FeatureFlagsError``
