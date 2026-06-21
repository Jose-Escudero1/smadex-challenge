//
//  FeatureFlagsRemoteProvider.swift
//  FeatureFlagsKit
//
//  Created by Jose Escudero on 21/6/26.
//

import Foundation

/// Contrato de la fuente remota de feature flags.
public protocol FeatureFlagsRemoteProvider: Sendable {
    /// Obtiene el conjunto actual de flags desde la fuente remota
    func fetchFlags(completion: @escaping @Sendable (Result<[String: FeatureFlagValue], Error>) -> Void)
}
