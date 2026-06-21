//
//  FeatureFlagsError.swift
//  FeatureFlagsKit
//
//  Created by Jose Escudero on 21/6/26.
//

import Foundation

/// Errores expuestos públicamente por el SDK
public enum FeatureFlagsError: Error {
    /// El proveedor remoto devolvió un error al sincronizar
    case remoteFetchFailed(underlying: Error)
}
