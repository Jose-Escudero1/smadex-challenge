//
//  FeatureFlagsClient.swift
//  FeatureFlagsKit
//
//  Created by Jose Escudero on 21/6/26.
//

import Foundation

/// Punto de entrada público del SDK
public actor FeatureFlagsClient {

    private let repository: FlagRepositoryProtocol
    private var cache: [String: FeatureFlagValue]
    private var overrides: [String: FeatureFlagValue] = [:]

    // MARK: - Inicialización

    /// Crea un cliente con un proveedor remoto y un conjunto de valores por defecto
    public init(remoteProvider: FeatureFlagsRemoteProvider, localDefaults: [String: FeatureFlagValue]) {
        let localSource = LocalFlagDataSource()
        self.repository = FlagRepository(remoteProvider: remoteProvider,
                                         localSource: localSource,
                                         localDefaults: localDefaults)
        self.cache = localSource.loadCachedFlags()
    }

    /// Inicializador interno que permite inyectar la fuente local
    internal init(remoteProvider: FeatureFlagsRemoteProvider, localDefaults: [String: FeatureFlagValue], localSource: LocalFlagDataSourceProtocol) {
        self.repository = FlagRepository(remoteProvider: remoteProvider,
                                         localSource: localSource,
                                         localDefaults: localDefaults)
        self.cache = localSource.loadCachedFlags()
    }

    // MARK: - Sincronización (escritura del estado compartido)

    /// Obtiene los flags remotos y actualiza la cache
    public func refresh() async throws {
        let flags = try await repository.fetchAndPersist()
        cache = flags
    }

    // MARK: - Lectura sin tipar

    /// Devuelve el valor crudo resuelto para una clave
    public func value(for key: String) -> FeatureFlagValue? {
        repository.resolve(key: key, cache: cache, overrides: overrides)
    }

    // MARK: - Lectura tipada por cadena

    /// Valor booleano del flag
    public func boolValue(for key: String) -> Bool {
        if case .bool(let value)? = value(for: key) {
            return value
        }
        return false
    }

    /// Valor entero del flag
    public func intValue(for key: String) -> Int {
        if case .int(let value)? = value(for: key) {
            return value
        }
        return 0
    }

    /// Valor Double del flag
    public func doubleValue(for key: String) -> Double {
        if case .double(let value)? = value(for: key) {
            return value
        }
        return 0
    }

    /// Valor String del flag
    public func stringValue(for key: String) -> String {
        if case .string(let value)? = value(for: key) {
            return value
        }
        return ""
    }

    // MARK: - Lectura type-safe

    /// Lee un flag usando una clave
    public func value<K: FeatureFlagKey, T>(for key: K, as type: T.Type) -> T? {
        decode(value(for: key.rawValue), as: type)
    }

    /// Variante de la lectura usando un String
    public func value<T>(for key: String, as type: T.Type) -> T? {
        decode(value(for: key), as: type)
    }

    // MARK: - Overrides de debug

    /// Fija un override local que tiene prioridad sobre la cache
    public func setOverride(_ value: FeatureFlagValue?, for key: String) {
        overrides[key] = value
    }

    /// Elimina todos los overrides
    public func clearOverrides() {
        overrides.removeAll()
    }

    // MARK: - Conversión interna

    private func decode<T>(_ value: FeatureFlagValue?, as type: T.Type) -> T? {
        switch value {
        case .bool(let v):
            return v as? T
        case .int(let v):
            return v as? T
        case .double(let v):
            return v as? T
        case .string(let v):
            return v as? T
        case .codable(let data):
            guard let decodableType = T.self as? any Decodable.Type
            else {
                return nil
            }
            return (try? decodableType.decode(from: data)) as? T
        case .none:
            return nil
        }
    }
}

// MARK: - Decodificación de existenciales

private extension Decodable {
    /// Decodifica una instancia del tipo concreto a partir de datos JSON
    static func decode(from data: Data) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
}
