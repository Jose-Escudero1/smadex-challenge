//
//  FeatureFlagKey.swift
//  FeatureFlagsKit
//
//  Created by Jose Escudero on 21/6/26.
//

/// Contrato para describir claves de flags de forma type-safe
public protocol FeatureFlagKey {
    /// Identificador del flag tal como llega desde la fuente remota / local
    var rawValue: String { get }
}
