//
//  DemoRemoteProvider.swift
//  FeatureFlagsDemo
//
//  Proveedor remoto simulado: parsea un JSON embebido (como si viniera de un
//  backend) tras un retardo artificial. Permite forzar un fallo para demostrar
//  el comportamiento de fallback y el estado de error en la UI.
//

import Foundation
import FeatureFlagsKit

final class DemoRemoteProvider: FeatureFlagsRemoteProvider, @unchecked Sendable {

    private let lock = NSLock()
    private var _payloadJSON: String
    private let latency: TimeInterval

    init(latency: TimeInterval = 1.2) {
        self.latency = latency
        self._payloadJSON = Self.defaultJSON
    }

    /// JSON que devolverá el "servidor" en el próximo fetch. Permite que la app
    /// inyecte una petición pegada por el usuario.
    func setPayloadJSON(_ json: String) {
        lock.withLock { _payloadJSON = json }
    }

    func fetchFlags(
        completion: @escaping @Sendable (Result<[String: FeatureFlagValue], Error>) -> Void
    ) {
        let json = lock.withLock { _payloadJSON }
        DispatchQueue.global().asyncAfter(deadline: .now() + latency) {
            do {
                let flags = try Self.parse(json: json)
                completion(.success(flags))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Carga simulada

    /// Respuesta JSON por defecto, tal como llegaría de un backend real.
    private static let defaultJSON = """
    {
        "new_home_enabled": true,
        "home_title": "Nueva Home (remota)",
        "home_max_items": 8
    }
    """

    /// Convierte un JSON genérico en `[String: FeatureFlagValue]` infiriendo el tipo.
    private static func parse(json: String) throws -> [String: FeatureFlagValue] {
        guard let data = json.data(using: .utf8) else { return [:] }
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else { return [:] }

        var flags: [String: FeatureFlagValue] = [:]
        for (key, raw) in dictionary {
            switch raw {
            case let number as NSNumber:
                if CFGetTypeID(number) == CFBooleanGetTypeID() {
                    flags[key] = .bool(number.boolValue)
                } else if CFNumberIsFloatType(number) {
                    flags[key] = .double(number.doubleValue)
                } else {
                    flags[key] = .int(number.intValue)
                }
            case let string as String:
                flags[key] = .string(string)
            default:
                continue
            }
        }
        return flags
    }
}
