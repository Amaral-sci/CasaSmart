//
//  NovaDigitalError.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 12/08/26.
//

import Foundation

enum NovaDigitalError: LocalizedError, Error {

    case ipAusente
    case localKeyAusente
    case localKeyInvalida
    case conexaoFalhou
    case handshakeFalhou
    case respostaInvalida
    case deviceIDAusente
    case timeout


    var errorDescription: String? {

        switch self {

        case .ipAusente:
            return "O dispositivo não possui IP."

        case .localKeyAusente:
            return "Local Key ausente."

        case .localKeyInvalida:
            return "Local Key inválida."

        case .conexaoFalhou:
            return "Falha na conexão TCP."

        case .handshakeFalhou:
            return "Falha no handshake Tuya."

        case .respostaInvalida:
            return "Resposta Tuya inválida."

        case .deviceIDAusente:
            return "Device ID ausente."

        case .timeout:
            return "Timeout."
        }
    }
}
