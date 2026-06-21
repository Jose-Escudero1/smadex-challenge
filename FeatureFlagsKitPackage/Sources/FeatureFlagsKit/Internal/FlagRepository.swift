//
//  FlagRepository.swift
//  FeatureFlagsKit
//
//  Created by Jose Escudero on 21/6/26.
//

import Foundation

/// Coordina la obtención remota, la persistencia local y la resolución con fallback.
internal protocol FlagRepositoryProtocol: Sendable {
    /// Resuelve un valor aplicando el orden de prioridad: override → caché → defaults.
    func resolve(key: String, cache: [String: FeatureFlagValue], overrides: [String: FeatureFlagValue]) -> FeatureFlagValue?

    /// Carga la caché persistida en disco.
    func loadPersistedCache() -> [String: FeatureFlagValue]

    /// Obtiene los flags remotos, los persiste y los devuelve.
    func fetchAndPersist() async throws -> [String: FeatureFlagValue]
}

internal struct FlagRepository: FlagRepositoryProtocol {

    private let remoteProvider: FeatureFlagsRemoteProvider
    private let localSource: LocalFlagDataSourceProtocol
    private let localDefaults: [String: FeatureFlagValue]

    internal init(remoteProvider: FeatureFlagsRemoteProvider, localSource: LocalFlagDataSourceProtocol, localDefaults: [String: FeatureFlagValue]) {
        self.remoteProvider = remoteProvider
        self.localSource = localSource
        self.localDefaults = localDefaults
    }

    internal func resolve(key: String, cache: [String: FeatureFlagValue], overrides: [String: FeatureFlagValue]) -> FeatureFlagValue? {
        if let override = overrides[key] {
            return override
        }
        if let cached = cache[key] {
            return cached
        }
        return localDefaults[key]
    }

    internal func loadPersistedCache() -> [String: FeatureFlagValue] {
        localSource.loadCachedFlags()
    }

    internal func fetchAndPersist() async throws -> [String: FeatureFlagValue] {
        let flags: [String: FeatureFlagValue]
        do {
            flags = try await withCheckedThrowingContinuation { continuation in
                remoteProvider.fetchFlags { result in
                    continuation.resume(with: result)
                }
            }
        } catch {
            throw FeatureFlagsError.remoteFetchFailed(underlying: error)
        }
        localSource.save(flags)
        return flags
    }
}
