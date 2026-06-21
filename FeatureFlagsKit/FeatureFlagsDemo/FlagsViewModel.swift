//
//  FlagsViewModel.swift
//  FeatureFlagsDemo
//
//  Puente entre el `actor` FeatureFlagsClient y la UI de SwiftUI.
//  Aislado a @MainActor: todas las propiedades observables se mutan en el hilo
//  principal, y las llamadas al cliente se hacen con `await`.
//

import Foundation
import Observation
import FeatureFlagsKit

@MainActor
@Observable
final class FlagsViewModel {

    // Estado mostrado en la UI.
    private(set) var isHomeEnabled = false
    private(set) var homeTitle = ""
    private(set) var maxItems = 0
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let provider: DemoRemoteProvider
    private let client: FeatureFlagsClient

    init() {
        let provider = DemoRemoteProvider()
        self.provider = provider
        self.client = FeatureFlagsClient(
            remoteProvider: provider,
            localDefaults: AppFlag.localDefaults
        )
    }

    /// Sincroniza con el remoto y refresca los valores mostrados.
    func refresh() async {
        isLoading = true
        errorMessage = nil
        do {
            try await client.refresh()
        } catch {
            errorMessage = "No se pudieron actualizar los flags (error de red o JSON inválido). Mostrando los últimos valores conocidos."
        }
        await reloadValues()
        isLoading = false
    }

    /// Inyecta un JSON pegado por el usuario como si fuera la respuesta del servidor
    /// y sincroniza. El JSON pasa por el flujo real del SDK (proveedor → refresh → caché).
    func applyPastedJSON(_ json: String) async {
        provider.setPayloadJSON(json)
        await refresh()
    }

    /// Lee los valores resueltos actuales (caché remota o fallback local).
    func reloadValues() async {
        isHomeEnabled = await client.value(for: AppFlag.newHomeEnabled, as: Bool.self) ?? false
        homeTitle = await client.stringValue(for: AppFlag.homeTitle.rawValue)
        maxItems = await client.intValue(for: AppFlag.homeMaxItems.rawValue)
    }
}
