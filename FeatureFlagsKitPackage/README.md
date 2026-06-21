# FeatureFlagsKit (Swift Package)

Versión SPM del SDK `FeatureFlagsKit`. Mismo código y misma API pública que el framework, distribuida como paquete Swift.

- **Plataformas:** iOS 16+, macOS 13+
- **Swift tools:** 6.0 (modo Swift 6, strict concurrency)
- **Dependencias de terceros:** ninguna

## Uso rápido

Dentro de la carpeta `FeatureFlagsKitPackage`:

```bash
swift build      # compila la librería
swift test       # ejecuta la suite (Swift Testing)
```

## Integrar en otro proyecto

Este paquete vive en la subcarpeta `FeatureFlagsKitPackage` del repositorio, no en su raíz. Por eso la forma recomendada de integrarlo es como **paquete local**.

Desde una app de Xcode: **File → Add Package Dependencies → Add Local…** y selecciona la carpeta `FeatureFlagsKitPackage`.

Desde otro paquete Swift, en su `Package.swift` (la ruta es relativa a ese manifiesto; ajústala a dónde tengas el paquete):

```swift
dependencies: [
    .package(path: ".../smadex-challenge/FeatureFlagsKitPackage")
],
targets: [
    .target(
        name: "MiApp",
        dependencies: [
            .product(name: "FeatureFlagsKit", package: "FeatureFlagsKitPackage")
        ]
    )
]
```

Sobre esos dos valores: `name` es el nombre del producto (la librería `FeatureFlagsKit`), y `package` es la identidad del paquete. Cuando la dependencia es por ruta, la identidad coincide con el nombre de la carpeta, es decir `FeatureFlagsKitPackage`.

Nota sobre la instalación por URL: SPM busca el `Package.swift` en la raíz del repositorio. Como aquí está dentro de la subcarpeta `FeatureFlagsKitPackage`, no se puede instalar por URL directamente. Para permitirlo habría que mover el contenido del paquete a la raíz del repositorio o publicarlo en su propio repositorio.

## Estructura

```
FeatureFlagsKitPackage/
├── Package.swift
├── Sources/FeatureFlagsKit/     (Public/ + Internal/ + FeatureFlagsKit.docc)
└── Tests/FeatureFlagsKitTests/  (suite + Support/TestDoubles.swift)
```

La API pública, la arquitectura y las decisiones de diseño están documentadas en el README de la raíz del repositorio.
