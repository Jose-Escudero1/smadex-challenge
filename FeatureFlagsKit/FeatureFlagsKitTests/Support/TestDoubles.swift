//
//  TestDoubles.swift
//  FeatureFlagsKitTests
//
//  Mocks ligeros y deterministas: ni red real ni disco real.
//

import Foundation
@testable import FeatureFlagsKit

/// Error de prueba `Sendable` para escenarios de fallo remoto.
struct MockError: Error, Equatable {
    let message: String
    static let unreachable = MockError(message: "unreachable")
}

/// Proveedor remoto falso, configurable y seguro para concurrencia.
///
/// Permite simular éxito/fallo, retardo y contar el número de fetches realizados.
final class MockRemoteProvider: FeatureFlagsRemoteProvider, @unchecked Sendable {

    enum Behavior: Sendable {
        case success([String: FeatureFlagValue])
        case failure(MockError)
    }

    private let lock = NSLock()
    private var _behavior: Behavior
    private var _fetchCount = 0
    private let delay: TimeInterval

    init(behavior: Behavior, delay: TimeInterval = 0) {
        self._behavior = behavior
        self.delay = delay
    }

    var fetchCount: Int {
        lock.withLock { _fetchCount }
    }

    func setBehavior(_ behavior: Behavior) {
        lock.withLock { _behavior = behavior }
    }

    func fetchFlags(
        completion: @escaping @Sendable (Result<[String: FeatureFlagValue], Error>) -> Void
    ) {
        let behavior: Behavior = lock.withLock {
            _fetchCount += 1
            return _behavior
        }
        let work: @Sendable () -> Void = {
            switch behavior {
            case .success(let flags):
                completion(.success(flags))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        if delay > 0 {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: work)
        } else {
            DispatchQueue.global().async(execute: work)
        }
    }
}

/// Fuente local en memoria, segura para concurrencia, para tests deterministas.
final class InMemoryLocalDataSource: LocalFlagDataSourceProtocol, @unchecked Sendable {

    private let lock = NSLock()
    private var storage: [String: FeatureFlagValue]

    init(initial: [String: FeatureFlagValue] = [:]) {
        self.storage = initial
    }

    func loadCachedFlags() -> [String: FeatureFlagValue] {
        lock.withLock { storage }
    }

    func save(_ flags: [String: FeatureFlagValue]) {
        lock.withLock { storage = flags }
    }

    func clear() {
        lock.withLock { storage = [:] }
    }
}
