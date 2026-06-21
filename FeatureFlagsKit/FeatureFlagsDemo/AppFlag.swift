//
//  AppFlag.swift
//  FeatureFlagsDemo
//
//  Definición type-safe de los flags que consume la app de demostración.
//

import FeatureFlagsKit

/// Claves de flags de la app, fuertemente tipadas mediante `FeatureFlagKey`.
enum AppFlag: String, FeatureFlagKey, CaseIterable {
    case newHomeEnabled = "new_home_enabled"
    case homeTitle = "home_title"
    case homeMaxItems = "home_max_items"
}

extension AppFlag {
    /// Valores de respaldo locales usados cuando falla la red o falta un flag.
    static let localDefaults: [String: FeatureFlagValue] = [
        AppFlag.newHomeEnabled.rawValue: .bool(false),
        AppFlag.homeTitle.rawValue: .string("Bienvenido (por defecto)"),
        AppFlag.homeMaxItems.rawValue: .int(20)
    ]
}
