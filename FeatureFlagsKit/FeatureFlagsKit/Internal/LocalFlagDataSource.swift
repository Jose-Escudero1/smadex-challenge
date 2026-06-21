//
//  LocalFlagDataSource.swift
//  FeatureFlagsKit
//
//  Created by Jose Escudero on 21/6/26.
//

import Foundation

/// Almacenamiento local de la caché de flags (persistencia entre lanzamientos)
internal protocol LocalFlagDataSourceProtocol: Sendable {
    /// Carga los flags almacenados
    func loadCachedFlags() -> [String: FeatureFlagValue]
    /// Persiste el conjunto de flags, reemplazando lo anterior
    func save(_ flags: [String: FeatureFlagValue])
    /// Elimina toda la cache
    func clear()
}

internal struct LocalFlagDataSource: LocalFlagDataSourceProtocol, @unchecked Sendable {

    private let userDefaults: UserDefaults
    private let storageKey: String

    internal init(userDefaults: UserDefaults = .standard, storageKey: String = "com.featureflagskit.cache.flags") {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
    }

    internal func loadCachedFlags() -> [String: FeatureFlagValue] {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: FeatureFlagValue].self, from: data)
        else {
            return [:]
        }
        return decoded
    }

    internal func save(_ flags: [String: FeatureFlagValue]) {
        guard let data = try? JSONEncoder().encode(flags)
        else {
            return
        }
        userDefaults.set(data, forKey: storageKey)
    }

    internal func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}
