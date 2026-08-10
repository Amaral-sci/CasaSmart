//
//  NovaDigitalService.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import Foundation
import Network

final class NovaDigitalService {
    
    static let shared = NovaDigitalService()
    
    private init() {}
    
    
    // MARK: - Ligar / Desligar
    
    func setPower(
        _ isOn: Bool,
        device: Device
    ) async throws {
        if isOn {
            try await turnOn(
                device: device
            )
        } else {
            try await turnOff(
                device: device
            )
        }
    }
    
    func toggle(
        device: Device
    ) async throws {
        
        if device.isOn {
            
            try await turnOn(
                device: device
            )
            
        } else {
            
            try await turnOff(
                device: device
            )
            
        }
        
    }
    
    
    // MARK: - Ligar
    
    func turnOn(
        device: Device
    ) async throws {
        
        guard let ip = device.ip else {
            throw NovaDigitalError.ipAusente
        }
        
        print("Ligando \(device.name)")
        print("IP:", ip)
        
        // Próximo passo:
        // enviar pacote Tuya para o dispositivo
        
    }
    
    
    // MARK: - Desligar
    
    func turnOff(
        device: Device
    ) async throws {
        
        guard let ip = device.ip else {
            throw NovaDigitalError.ipAusente
        }
        
        print("Desligando \(device.name)")
        print("IP:", ip)
        
        // Próximo passo:
        // enviar pacote Tuya para o dispositivo
        
    }
    
    
    // MARK: - Testar conexão
    
    func ping(
        device: Device
    ) async -> Bool {
        
        guard let ip = device.ip else {
            return false
        }
        
        return await checkConnection(
            ip: ip
        )
    }
    
    
    // MARK: - Conexão TCP
    
    private func checkConnection(
        ip: String
    ) async -> Bool {
        guard let port = NWEndpoint.Port(rawValue: 6668) else {
            return false
        }
        
        return await withCheckedContinuation { continuation in
            let state = ConnectionProbeState(
                continuation: continuation
            )
            
            let connection = NWConnection(
                host: NWEndpoint.Host(ip),
                port: port,
                using: .tcp
            )
            
            state.setConnection(connection)
            
            connection.stateUpdateHandler = { [state] connectionState in
                let result: Bool?

                switch connectionState {
                case .ready:
                    result = true

                case .failed,
                     .cancelled:
                    result = false

                default:
                    result = nil
                }

                guard let result else {
                    return
                }

                Task { @MainActor in
                    state.finish(
                        with: result
                    )
                }
            }
            connection.start(
                queue: DispatchQueue.global(
                    qos: .userInitiated
                )
            )
            
            DispatchQueue.global().asyncAfter(
                deadline: .now() + 5
            ) { [state] in
                Task { @MainActor in
                    state.finish(
                        with: false
                    )
                }
            }
        }
    }
    private final class ConnectionProbeState: @unchecked Sendable {

        private let lock = NSLock()

        private var continuation:
            CheckedContinuation<Bool, Never>?

        private var connection: NWConnection?

        init(
            continuation: CheckedContinuation<Bool, Never>
        ) {
            self.continuation = continuation
        }

        func setConnection(
            _ connection: NWConnection
        ) {
            lock.lock()
            self.connection = connection
            lock.unlock()
        }

        func finish(
            with result: Bool
        ) {
            lock.lock()

            guard let continuation else {
                lock.unlock()
                return
            }

            self.continuation = nil

            let connection = self.connection
            self.connection = nil

            lock.unlock()

            connection?.cancel()

            continuation.resume(
                returning: result
            )
        }
    }
}

// MARK: - Erros

enum NovaDigitalError: LocalizedError {

    case ipAusente
    case conexaoFalhou
    case comandoFalhou

    var errorDescription: String? {

        switch self {

        case .ipAusente:
            return "O dispositivo não possui um endereço IP."

        case .conexaoFalhou:
            return "Não foi possível conectar ao dispositivo."

        case .comandoFalhou:
            return "O dispositivo recusou o comando."
        }
    }
}
