//
//  NovaDigitalService.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

    

import Foundation
import Network
import CryptoSwift


final class NovaDigitalService {

    static let shared = NovaDigitalService()

    private init() {}

    // MARK: - Configuração

    private let tuyaPort: UInt16 = 6668

    private let protocolVersion = "3.4"

    private let powerDP = "switch_1"

    private var sequence: UInt32 = 0


    // MARK: - ON / OFF

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

        try await setPower(
            !device.isOn,
            device: device
        )
    }


    func turnOn(
        device: Device
    ) async throws {

        print("================================")
        print("TUYA ON")
        print("Dispositivo:", device.name)
        print("DP:", powerDP)
        print("Valor: true")
        print("================================")

        try await sendPowerCommand(
            true,
            device: device
        )
    }


    func turnOff(
        device: Device
    ) async throws {

        print("================================")
        print("TUYA OFF")
        print("Dispositivo:", device.name)
        print("DP:", powerDP)
        print("Valor: false")
        print("================================")

        try await sendPowerCommand(
            false,
            device: device
        )
    }


    // MARK: - Teste de conexão

    func testConnection(
        device: Device
    ) async {

        do {

            guard let ip = device.ip,
                  !ip.isEmpty else {

                throw NovaDigitalError.ipAusente
            }

            guard let localKeyString = device.localKey,
                  !localKeyString.isEmpty else {

                throw NovaDigitalError.localKeyAusente
            }
            let key = try TuyaCrypto.shared.makeAESKey(
                from: localKeyString
            )

            print("================================")
            print("TUYA LAN")
            print("Protocolo:", protocolVersion)
            print("IP:", ip)
            print("Porta:", tuyaPort)
            print("DP:", powerDP)
            print("Local Key: OK")
            print("AES Key:", key.count, "bytes")
            print("================================")

            let connection = try await TuyaTCPClient.shared.connect(ip: ip)

            connection.cancel()

            print("TCP conectado com sucesso.")

        } catch {

            print("================================")
            print("ERRO TUYA")
            print(error.localizedDescription)
            print("================================")
        }
    }


    // MARK: - Testar Handshake

    func testHandshake(
        device: Device
    ) async {

        do {

            guard let ip = device.ip,
                  !ip.isEmpty else {

                throw NovaDigitalError.ipAusente
            }

            guard let localKeyString = device.localKey,
                  !localKeyString.isEmpty else {

                throw NovaDigitalError.localKeyAusente
            }

            let localKey = try TuyaCrypto.shared.makeAESKey(
                from: localKeyString
            )

            print("================================")
            print("TUYA 3.4 HANDSHAKE")
            print("IP:", ip)
            print("Device ID:", device.virtualID ?? "sem ID")
            print("Local Key: OK")
            print("================================")

            let connection = try await TuyaTCPClient.shared.connect(ip: ip)
            
            defer {
                connection.cancel()
            }

            print("TCP conectado")

            let sessionKey = try await TuyaHandshake.shared.performHandshake(
                connection: connection,
                localKey: localKey
            )

            print("Session Key criada")

            print("Session Key:", sessionKey.map {String(format: "%02X", $0)}
                    .joined()
            )

            print("================================")
            print("TUYA 3.4 HANDSHAKE OK")
            print("================================")

        } catch {

            print("================================")
            print("TUYA 3.4 HANDSHAKE ERRO")
            print(error.localizedDescription)
            print("================================")
        }
    }


    // MARK: - Comunicação ON/OFF

    private func sendPowerCommand(
        _ isOn: Bool,
        device: Device
    ) async throws {

        guard let ip = device.ip,
              !ip.isEmpty else {

            throw NovaDigitalError.ipAusente
        }

        guard let localKeyString = device.localKey,
              !localKeyString.isEmpty else {

            throw NovaDigitalError.localKeyAusente
        }

        let localKey = try TuyaCrypto.shared.makeAESKey(
            from: localKeyString
        )

        let connection = try await TuyaTCPClient.shared.connect(ip: ip)

        defer {
            connection.cancel()
        }

        print("TCP conectado")

        let sessionKey = try await TuyaHandshake.shared.performHandshake(
            connection: connection,
            localKey: localKey
        )

        print("Handshake concluído")

        let packet = try makeControlPacket(
            isOn: isOn,
            device: device,
            sessionKey: sessionKey,
            localKey: localKey
        )
        print("Enviando CONTROL...")

        try await TuyaTCPClient.shared.send( packet, connection: connection)
        print("CONTROL enviado")

        // Aguarda uma possível resposta do dispositivo.
        //
        // Alguns dispositivos respondem com ACK.
        // Não consideramos ausência de ACK como falha
        // neste primeiro teste.

        do {
            let response = try await TuyaTCPClient.shared.receive(connection: connection)
            print( "Resposta recebida:", response.count,"bytes")
            
        } catch {
            print( "Nenhum ACK recebido:", error.localizedDescription)
        }

        print("================================")
        print("COMANDO ENVIADO:", isOn ? "ON" : "OFF")
        print("================================")
    }
    
    // MARK: -

    private func parsePowerState(
        _ data: Data,
        sessionKey: Data
    ) throws -> Bool {


        let frame =
        try TuyaFrame.shared.parse(
            data
        )


        let decrypted =
        try TuyaCrypto.shared.decryptECB(
            frame.payload,
            key: sessionKey
        )

        print("==============================")
        print("PAYLOAD DESCRIPTOGRAFADO")
        print(
            String(data: decrypted, encoding: .utf8)
            ?? "Não convertido para texto"
        )
        print("==============================")

        guard
            let jsonStart =
                decrypted.firstIndex(
                    of: UInt8(ascii: "{")
                )
        else {

            throw NovaDigitalError.respostaInvalida
        }


        let jsonData =
        decrypted[jsonStart...]


        let object =
        try JSONSerialization.jsonObject(
            with: jsonData
        )


        guard let dictionary =
                object as? [String:Any]
        else {

            throw NovaDigitalError.respostaInvalida
        }



        if let dps =
            dictionary["dps"]
                as? [String:Any]
        {


            if let state =
                dps["switch_1"]
                    as? Bool
            {

                return state
            }


            if let state =
                dps["1"]
                    as? Bool
            {

                return state
            }
        }


        throw NovaDigitalError.respostaInvalida
    }

    // MARK: - Buscar estado real

    func getPowerState(
        device: Device
    ) async throws -> Bool {

        guard let ip = device.ip,
              !ip.isEmpty else {
            throw NovaDigitalError.ipAusente
        }

        guard let localKeyString = device.localKey,
              !localKeyString.isEmpty else {
            throw NovaDigitalError.localKeyAusente
        }


        let localKey = try TuyaCrypto.shared.makeAESKey(
            from: localKeyString
        )


        let connection =
        try await TuyaTCPClient.shared.connect(
            ip: ip
        )


        defer {
            connection.cancel()
        }


        let sessionKey =
        try await TuyaHandshake.shared.performHandshake(
            connection: connection,
            localKey: localKey
        )


        let packet =
        try makeQueryPacket(
            device: device,
            sessionKey: sessionKey,
            localKey: localKey
        )


        try await TuyaTCPClient.shared.send(
            packet,
            connection: connection
        )


        let response =
        try await TuyaTCPClient.shared.receive(
            connection: connection
        )


        return try parsePowerState(
            response,
            sessionKey: sessionKey
        )
    }
    // MARK: - CONTROL

    private func makeControlPacket(
        isOn: Bool,
        device: Device,
        sessionKey: Data,
        localKey: Data
    ) throws -> Data {

        guard let deviceID = device.virtualID,
              !deviceID.isEmpty else {

            throw NovaDigitalError.deviceIDAusente
        }

        let timestamp = String(
            Int(Date().timeIntervalSince1970)
        )

        let json: [String: Any] = [

            "devId": deviceID,

            "uid": deviceID,

            "t": timestamp,

            "dps": [

                "switch_1": isOn
            ]
        ]

        let jsonData = try JSONSerialization.data(
            withJSONObject: json,
            options: []
        )

        // -----------------------------------------------------
        // 3.4 version header
        //
        // 15 bytes:
        //
        // "3.4"
        // + 12 bytes
        //
        // The entire payload is encrypted.
        // -----------------------------------------------------

        var plaintext = Data()

        plaintext.append(
            Data("3.4".utf8)
        )

        plaintext.append(
            Data( repeating: 0,count: 12 )
        )

        plaintext.append(
            jsonData
        )

        let encrypted = try TuyaCrypto.shared.encryptECB(
            plaintext,
            key: sessionKey,
            padding: .pkcs7
        )


        return TuyaFrame.shared.makeFrame(
            sequence: nextSequence(),
            command: 0x07,
            payload: encrypted,
            key: localKey,
            hmacMode: TuyaFrame.HMACMode.fullFrame
        )
    }


    // MARK: -

    private func makeQueryPacket(
        device: Device,
        sessionKey: Data,
        localKey: Data
    ) throws -> Data {


        let json:[String:Any] = [

            "devId": device.virtualID ?? "",

            "uid": device.virtualID ?? "",

            "t":
                String(
                    Int(Date().timeIntervalSince1970)
                )
        ]


        let jsonData =
        try JSONSerialization.data(
            withJSONObject: json
        )


        var plaintext = Data()


        plaintext.append(
            Data("3.4".utf8)
        )


        plaintext.append(
            Data(
                repeating: 0,
                count: 12
            )
        )


        plaintext.append(
            jsonData
        )


        let encrypted =
        try TuyaCrypto.shared.encryptECB(
            plaintext,
            key: sessionKey,
            padding: .pkcs7
        )


        return TuyaFrame.shared.makeFrame(
            sequence: nextSequence(),
            command: 0x0A,
            payload: encrypted,
            key: localKey,
            hmacMode: .fullFrame
        )
    }

    // MARK: - HEX String -> Data

    private func hexToData(_ string: String) -> Data {

        var data = Data()

        var index = string.startIndex

        while index < string.endIndex {

            let nextIndex = string.index(
                index,
                offsetBy: 2,
                limitedBy: string.endIndex
            )

            guard let nextIndex else {
                break
            }

            let byteString = String(
                string[index..<nextIndex]
            )

            if let byte = UInt8(
                byteString,
                radix: 16
            ) {
                data.append(byte)
            }

            index = nextIndex
        }

        return data
    }
    
    
    // MARK: - Sequence

    private func nextSequence() -> UInt32 {

        sequence &+= 1

        if sequence == 0 {

            sequence = 1
        }

        return sequence
    }


    // MARK: - Ping

    func ping(
        device: Device
    ) async -> Bool {

        guard let ip = device.ip else {

            return false
        }

        do {

            let connection = try await TuyaTCPClient.shared.connect(ip: ip)

            connection.cancel()

            return true

        } catch {

            return false
        }
    }
}

