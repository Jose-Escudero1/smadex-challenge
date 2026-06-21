# FeatureFlagsKit (Swift Package)

Versión SPM del SDK `FeatureFlagsKit`. Mismo código y misma API pública que el framework, distribuida como paquete Swift.

- **Plataformas:** iOS 16+, macOS 13+
- **Swift tools:** 6.0 (modo Swift 6, strict concurrency)
- **Dependencias de terceros:** ninguna

## Uso rápido

```bash
swift build      # compila la librería
swift test       # ejecuta la suite (Swift Testing)
```

## Integrar en otro proyecto

```swift
// Remoto
.package(url: "https://github.com/<tu-usuario>/FeatureFlagsKit.git", from: "1.0.0")

// Local
.package(path: "../FeatureFlagsKitPackage")
```

Y en el target consumidor:

```swift
.product(name: "FeatureFlagsKit", package: "FeatureFlagsKit")
```

Desde una app Xcode: **File → Add Package Dependencies → Add Local…** y selecciona esta carpeta.

## Estructura

```
Package.swift
Sources/FeatureFlagsKit/   → Public/ + Internal/ + FeatureFlagsKit.docc
Tests/FeatureFlagsKitTests/ → suite + Support/TestDoubles.swift
```

La API pública, la arquitectura y las decisiones de diseño están documentadas en el README de la raíz del repositorio.
