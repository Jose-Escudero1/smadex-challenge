//
//  FeatureFlagsKitTests.swift
//  FeatureFlagsKitTests
//
//  Created by Jose Escudero on 21/6/26.
//

import Testing
import Foundation
@testable import FeatureFlagsKit

@Suite("FeatureFlagsClient")
struct FeatureFlagsClientTests {

    private let defaults: [String: FeatureFlagValue] = [
        "new_home_enabled": .bool(false),
        "home_max_items": .int(20),
        "home_title": .string("Default Title")
    ]

    private func makeClient(
        behavior: MockRemoteProvider.Behavior = .success([:]),
        delay: TimeInterval = 0,
        local: LocalFlagDataSourceProtocol = InMemoryLocalDataSource()
    ) -> (FeatureFlagsClient, MockRemoteProvider) {
        let provider = MockRemoteProvider(behavior: behavior, delay: delay)
        let client = FeatureFlagsClient(
            remoteProvider: provider,
            localDefaults: defaults,
            localSource: local
        )
        return (client, provider)
    }

    // MARK: - Fallback local

    @Test("Sin refresh, devuelve los valores por defecto locales")
    func fallbackReturnsLocalDefaults() async {
        let (client, _) = makeClient()
        await #expect(client.boolValue(for: "new_home_enabled") == false)
        await #expect(client.intValue(for: "home_max_items") == 20)
        await #expect(client.stringValue(for: "home_title") == "Default Title")
    }

    @Test("Clave inexistente devuelve el valor por defecto del tipo")
    func unknownKeyReturnsTypeDefault() async {
        let (client, _) = makeClient()
        await #expect(client.boolValue(for: "missing") == false)
        await #expect(client.intValue(for: "missing") == 0)
        await #expect(client.doubleValue(for: "missing") == 0)
        await #expect(client.stringValue(for: "missing") == "")
        await #expect(client.value(for: "missing") == nil)
    }

    // MARK: - Flujo de refresh

    @Test("refresh actualiza la caché con los valores remotos")
    func refreshUpdatesCache() async throws {
        let (client, provider) = makeClient(behavior: .success([
            "new_home_enabled": .bool(true),
            "home_title": .string("Remote Title")
        ]))

        await #expect(client.boolValue(for: "new_home_enabled") == false) // default antes del refresh
        try await client.refresh()

        await #expect(client.boolValue(for: "new_home_enabled") == true)
        await #expect(client.stringValue(for: "home_title") == "Remote Title")
        #expect(provider.fetchCount == 1)
    }

    // MARK: - Fallo remoto

    @Test("Un fallo remoto lanza error y conserva el fallback local")
    func remoteFailureThrowsAndFallsBack() async {
        let (client, _) = makeClient(behavior: .failure(.unreachable))

        await #expect(throws: FeatureFlagsError.self) {
            try await client.refresh()
        }
        // Tras el fallo se siguen sirviendo los defaults.
        await #expect(client.boolValue(for: "new_home_enabled") == false)
        await #expect(client.intValue(for: "home_max_items") == 20)
    }

    @Test("Un fallo posterior conserva la última caché válida")
    func failureAfterSuccessKeepsPreviousCache() async throws {
        let (client, provider) = makeClient(behavior: .success(["new_home_enabled": .bool(true)]))
        try await client.refresh()
        await #expect(client.boolValue(for: "new_home_enabled") == true)

        provider.setBehavior(.failure(.unreachable))
        await #expect(throws: FeatureFlagsError.self) {
            try await client.refresh()
        }
        // La caché válida previa permanece.
        await #expect(client.boolValue(for: "new_home_enabled") == true)
    }

    // MARK: - Tipo inválido

    @Test("Un tipo no coincidente cae al valor por defecto del tipo solicitado")
    func invalidTypeReturnsTypeDefault() async throws {
        let (client, _) = makeClient(behavior: .success(["home_title": .string("hello")]))
        try await client.refresh()

        await #expect(client.stringValue(for: "home_title") == "hello") // tipo correcto
        await #expect(client.boolValue(for: "home_title") == false)     // mismatch -> default
        await #expect(client.intValue(for: "home_title") == 0)          // mismatch -> default
    }

    // MARK: - Caché y persistencia

    @Test("La caché remota se persiste y se recupera en un cliente nuevo")
    func cacheIsPersistedAcrossClients() async throws {
        let suiteName = "test.featureflagskit.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let storageKey = "cache"
        let firstSource = LocalFlagDataSource(userDefaults: userDefaults, storageKey: storageKey)
        let provider = MockRemoteProvider(behavior: .success(["new_home_enabled": .bool(true)]))
        let firstClient = FeatureFlagsClient(
            remoteProvider: provider,
            localDefaults: defaults,
            localSource: firstSource
        )
        try await firstClient.refresh()

        // Un cliente nuevo que lee la misma persistencia recupera el valor cacheado
        // sin necesidad de volver a sincronizar.
        let secondSource = LocalFlagDataSource(userDefaults: userDefaults, storageKey: storageKey)
        let secondProvider = MockRemoteProvider(behavior: .failure(.unreachable))
        let secondClient = FeatureFlagsClient(
            remoteProvider: secondProvider,
            localDefaults: defaults,
            localSource: secondSource
        )
        await #expect(secondClient.boolValue(for: "new_home_enabled") == true)
        #expect(secondProvider.fetchCount == 0)
    }

    // MARK: - Codable (bonus)

    struct Theme: Codable, Equatable {
        let primaryColor: String
        let cornerRadius: Int
    }

    @Test("Soporta valores Codable vía value(for:as:)")
    func codableValueRoundTrips() async throws {
        let theme = Theme(primaryColor: "#FF0000", cornerRadius: 12)
        let (client, _) = makeClient(behavior: .success([
            "home_theme": try .encoding(theme)
        ]))
        try await client.refresh()

        let decoded = await client.value(for: "home_theme", as: Theme.self)
        #expect(decoded == theme)
        // Un tipo Codable incompatible devuelve nil en vez de fallar.
        await #expect(client.value(for: "home_title", as: Theme.self) == nil)
    }

    // MARK: - API type-safe

    enum AppFlag: String, FeatureFlagKey {
        case newHomeEnabled = "new_home_enabled"
        case homeMaxItems = "home_max_items"
    }

    @Test("API type-safe con clave fuertemente tipada")
    func typeSafeKeyAPI() async throws {
        let (client, _) = makeClient(behavior: .success([
            "new_home_enabled": .bool(true),
            "home_max_items": .int(42)
        ]))
        try await client.refresh()

        await #expect(client.value(for: AppFlag.newHomeEnabled, as: Bool.self) == true)
        await #expect(client.value(for: AppFlag.homeMaxItems, as: Int.self) == 42)
        await #expect(client.value(for: AppFlag.newHomeEnabled, as: String.self) == nil)
    }

    // MARK: - Overrides de debug (bonus)

    @Test("Los overrides tienen prioridad y pueden limpiarse")
    func debugOverridesTakePriority() async throws {
        let (client, _) = makeClient(behavior: .success(["new_home_enabled": .bool(true)]))
        try await client.refresh()
        await #expect(client.boolValue(for: "new_home_enabled") == true)

        await client.setOverride(.bool(false), for: "new_home_enabled")
        await #expect(client.boolValue(for: "new_home_enabled") == false)

        await client.clearOverrides()
        await #expect(client.boolValue(for: "new_home_enabled") == true)
    }

    // MARK: - Concurrencia

    @Test("Lecturas y refresh concurrentes no producen estado inconsistente")
    func concurrentReadsAndRefreshesAreSafe() async throws {
        let (client, _) = makeClient(behavior: .success(["new_home_enabled": .bool(true)]))

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<500 {
                group.addTask {
                    if index % 25 == 0 {
                        try? await client.refresh()
                    } else {
                        _ = await client.boolValue(for: "new_home_enabled")
                        _ = await client.intValue(for: "home_max_items")
                    }
                }
            }
        }

        // Tras la tormenta concurrente, al menos un refresh aplicó el valor remoto.
        try await client.refresh()
        await #expect(client.boolValue(for: "new_home_enabled") == true)
    }
}
