//
//  NovaDigitalService.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

    

import Foundation
import Network
import CryptoKit
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

            guard let localKey = device.localKey,
                  !localKey.isEmpty else {

                throw NovaDigitalError.localKeyAusente
            }

            let key = try makeAESKey(
                from: localKey
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

            let connection = try await connect(
                ip: ip
            )

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

            let localKey = try makeAESKey(
                from: localKeyString
            )

            print("================================")
            print("TUYA 3.4 HANDSHAKE")
            print("IP:", ip)
            print("Device ID:", device.virtualID ?? "sem ID")
            print("Local Key: OK")
            print("================================")

            let connection = try await connect(
                ip: ip
            )

            defer {
                connection.cancel()
            }

            print("TCP conectado")

            let sessionKey = try await performHandshake(
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

        let localKey = try makeAESKey(
            from: localKeyString
        )

        let connection = try await connect(
            ip: ip
        )

        defer {
            connection.cancel()
        }

        print("TCP conectado")

        let sessionKey = try await performHandshake(
            connection: connection,
            localKey: localKey
        )

        print("Handshake concluído")

        let packet = try makeControlPacket(
            isOn: isOn,
            device: device,
            sessionKey: sessionKey
        )

        print("Enviando CONTROL...")

        try await send(packet, connection: connection)

        print("CONTROL enviado")

        // Aguarda uma possível resposta do dispositivo.
        //
        // Alguns dispositivos respondem com ACK.
        // Não consideramos ausência de ACK como falha
        // neste primeiro teste.

        do {
            let response = try await receive(connection: connection, timeout: 2.0)

            print( "Resposta recebida:", response.count,"bytes")
        } catch {
            print( "Nenhum ACK recebido:", error.localizedDescription)
        }

        print("================================")
        print("COMANDO ENVIADO:", isOn ? "ON" : "OFF")
        print("================================")
    }

    // MARK: - Handshake Tuya 3.4

    private func performHandshake(
        connection: NWConnection,
        localKey: Data
    ) async throws -> Data {

        // =====================================================
        // 1. CLIENT NONCE
        // =====================================================

        var clientNonce = Data()

        for _ in 0..<16 {clientNonce.append(UInt8.random(in: 0...255))}

        print("Client nonce criado")
        print("Client nonce:",clientNonce.map {String(format: "%02X", $0)}
                .joined(separator: " "))


        // =====================================================
        // 2. START 0x03
        // =====================================================

        let startSequence = nextSequence()

        let startPacket = try makeHandshakeStartPacket(
            sequence: startSequence,
            clientNonce: clientNonce,
            localKey: localKey
        )

        print("================================")
        print("TUYA START")
        print( "Sequence:", startSequence )
        print("Command: 0x03")
        print( "Payload:", startPacket.count - 36,"bytes")
        print( "Frame:",startPacket.count, "bytes")
        print("================================")
        print("TUYA START FRAME")
        print("Bytes:", startPacket.count)
        print(startPacket.map {String(format: "%02X", $0)} .joined(separator: " "))
        print("================================")
       
        try await send( startPacket, connection: connection)
        print("START (0x03) enviado")


        // =====================================================
        // 3. RECEBER RESPOSTA
        // =====================================================

        let responsePacket = try await receive( connection: connection )

        print("================================")
        print("TUYA RESPONSE RAW")
        print( "Bytes:", responsePacket.count)
        print( responsePacket.map {String(format: "%02X", $0)}
                .joined(separator: " "))
        print("================================")


        // =====================================================
        // 4. PARSE
        // =====================================================

        let response = try parseFrame(
            responsePacket
        )

        print("================================")
        print("TUYA RESPONSE PARSED")
        print("Sequence:",response.sequence)
        print("Command:",String(format: "0x%08X",response.command))
        print( "Length:", response.length)
        print( "Retcode:", String( format: "0x%08X", response.retcode))
        print("Payload:", response.payload.count,"bytes")
        print( "HMAC:", response.hmac.count,"bytes" )
        print("================================")


        // =====================================================
        // 5. VALIDAR RETCODE
        // =====================================================

        guard response.retcode == 0 else {

            print("================================")
            print("TUYA REJEITOU O START")
            print("Retcode:",String(format: "0x%08X", response.retcode))
            print("================================")

            throw NovaDigitalError.handshakeFalhou
        }


        // =====================================================
        // 6. VALIDAR COMMAND
        // =====================================================

        guard response.command == 0x04 else {

            print("================================")
            print("TUYA RESPONSE COMMAND INVÁLIDO")
            print("Esperado:", "0x00000004")
            print("Recebido:", String(format: "0x%08X", response.command))
            print("================================")

            throw NovaDigitalError.handshakeFalhou
        }


        // =====================================================
        // 7. DESCRIPTOGRAFAR PAYLOAD
        // =====================================================

        guard response.payload.count % 16 == 0 else {

            print("PAYLOAD AES INVÁLIDO")
            print(response.payload.count)

            throw NovaDigitalError.handshakeFalhou
        }

        let decryptedResponse = try decryptECB(response.payload, key: localKey)

        print("DECRYPT SIZE:",decryptedResponse.count)
        print("================================")
        print("RESPONSE DESCRIPTOGRAFADO")
        print( "Bytes:", decryptedResponse.count)
        print(decryptedResponse.map {String(format: "%02X",$0)}
                .joined(separator: " "))
        print("================================")


        // =====================================================
        // 8. DEVICE NONCE
        // =====================================================

        guard decryptedResponse.count >= 64 else {
            
            print("DECRYPT SIZE INVÁLIDO")
            print("Esperado: 64")
            print("Recebido:", decryptedResponse.count)
            
            throw NovaDigitalError.handshakeFalhou
        }

        let deviceNonce = Data(decryptedResponse[0..<16])

        print( "DEVICE NONCE ASCII:", String(data: deviceNonce, encoding: .utf8) ?? "erro")

        
        let receivedHMAC = Data(decryptedResponse[16..<48])

        print("Device nonce:",deviceNonce.map {String(format: "%02X", $0)}
        .joined(separator: " "))

        print( "DEVICE NONCE STRING:",String(data: deviceNonce, encoding: .utf8) ?? "erro")

        print("CLIENT NONCE HEX:", clientNonce.map {String(format:"%02X",$0)}
            .joined(separator: " ")
        )
        // =====================================================
           // 9. VALIDAR HMAC TUYA 3.4
           // =====================================================




           let authKey = Data(
               HMAC<SHA256>.authenticationCode(
                   for: Data("3.4".utf8),
                   using: SymmetricKey(data: localKey)
               )
           )


           let keys = [

               ("LOCAL KEY", localKey),

               ("AUTH KEY", authKey)

           ]


           let messages = [

               ("3.4 + client + device",
                Data("3.4".utf8) + clientNonce + deviceNonce),


               ("3.4 + device + client",
                Data("3.4".utf8) + deviceNonce + clientNonce),


               ("client + device",
                clientNonce + deviceNonce),


               ("device + client",
                deviceNonce + clientNonce)

           ]


        print("================================")
        print("VALIDANDO HMAC")
        print("================================")


        var hmacValido = false


        for key in keys {

            for message in messages {

                let result = Data(
                    HMAC<SHA256>.authenticationCode(
                        for: message.1,
                        using: SymmetricKey(data: key.1)
                    )
                )


                if result == receivedHMAC {

                    print("HMAC ENCONTRADO")
                    print("CHAVE:", key.0)
                    print("MENSAGEM:", message.0)

                    hmacValido = true
                }
            }
        }


        guard hmacValido else {

            print("HMAC INVÁLIDO")

            throw NovaDigitalError.handshakeFalhou
        }


        print("HMAC VALIDADO")
           

        // =====================================================
        // 10. FINISH 0x05
        // =====================================================

        var finishData = Data()

        finishData.append(Data("3.4".utf8))

        finishData.append(deviceNonce)


        let finishHMAC = Data(HMAC<SHA256>.authenticationCode(for: finishData, using: SymmetricKey(data: localKey)))

        let encryptedFinish = try encryptECB(
            finishHMAC,
            key: localKey,
            padding: .noPadding
        )

        let finishSequence = nextSequence()

        let finishPacket = makeHandshakeFrame(
            sequence: finishSequence,
            command: 0x05,
            payload: encryptedFinish,
            key: localKey,
            deviceResponse: false
        )

        print("================================")
        print("TUYA FINISH")
        print(
            "Sequence:",
            finishSequence
        )
        print("Command: 0x05")
        print(
            "Payload:",
            encryptedFinish.count,
            "bytes"
        )
        print(
            "Frame:",
            finishPacket.count,
            "bytes"
        )
        print("================================")

        try await send(
            finishPacket,
            connection: connection
        )

        print("FINISH (0x05) enviado")


        // =====================================================
        // 11. DERIVAR SESSION KEY
        // =====================================================

        var sessionData = Data()

        sessionData.append(localKey)
        sessionData.append(clientNonce)
        sessionData.append(deviceNonce)


        let hash = SHA256.hash(
            data: sessionData
        )


        let sessionKey = Data(hash)


        print("SESSION KEY SHA256:")
        print(
            sessionKey.map {
                String(format:"%02X",$0)
            }
            .joined(separator:" ")
        )

        print("================================")
        print("SESSION KEY CRIADA")
        print(
            sessionKey
                .map {
                    String(
                        format: "%02X",
                        $0
                    )
                }
                .joined(separator: " ")
        )
        print("================================")

        return sessionKey
    }
    // MARK: - CONTROL

    private func makeControlPacket(
        isOn: Bool,
        device: Device,
        sessionKey: Data
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

                "1": isOn
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

        let encrypted = try encryptECB(
            plaintext,
            key: sessionKey,
            padding: .pkcs7
        )

        // 0x07 = CONTROL
        //
        // For this first command we use the normal
        // CONTROL frame. If the device responds with
        // "data unvalid", we will test CONTROL_NEW 0x0D.

        return makeHandshakeFrame(
            sequence: nextSequence(),
            command: 0x07,
            payload: encrypted,
            key: sessionKey,
            deviceResponse: false
        )
    }


    // MARK: - Frame 55AA

    private func makeHandshakeFrame(
        sequence: UInt32,
        command: UInt32,
        payload: Data,
        key: Data,
        deviceResponse: Bool
    ) -> Data {

        let prefix = Data([
            0x00,
            0x00,
            0x55,
            0xAA
        ])

        let footer = Data([
            0x00,
            0x00,
            0xAA,
            0x55
        ])

        // ---------------------------------------------------------
        // LENGTH
        //
        // Para CLIENTE -> DEVICE:
        //
        // payload + HMAC + footer
        //
        // Para DEVICE -> CLIENTE:
        //
        // retcode + payload + HMAC + footer
        // ---------------------------------------------------------

        let retcodeLength = deviceResponse ? 4 : 0

        let length = UInt32(
            retcodeLength
            + payload.count
            + 32
            + 4
        )

        // ---------------------------------------------------------
        // FRAME SEM HMAC
        // ---------------------------------------------------------

        var frame = Data()

        frame.append(prefix)

        frame.append(
            uint32BE(sequence)
        )

        frame.append(
            uint32BE(command)
        )

        frame.append(
            uint32BE(length)
        )

        // ---------------------------------------------------------
        // RETCODE
        //
        // Somente DEVICE -> CLIENT
        // ---------------------------------------------------------

        if deviceResponse {

            frame.append(
                uint32BE(0)
            )
        }

        // ---------------------------------------------------------
        // PAYLOAD
        // ---------------------------------------------------------

        frame.append(payload)

        // ---------------------------------------------------------
        // HMAC
        //
        // HMAC cobre tudo desde 55AA até o payload.
        // ---------------------------------------------------------

        let hmac = Data(
            HMAC<SHA256>.authenticationCode(
                for: frame,
                using: SymmetricKey(
                    data: key
                )
            )
        )

        frame.append(hmac)

        // ---------------------------------------------------------
        // FOOTER
        // ---------------------------------------------------------

        frame.append(footer)

        return frame
    }
    
    // MARK: - START Packet 0x03

    private func makeHandshakeStartPacket(
        sequence: UInt32,
        clientNonce: Data,
        localKey: Data
    ) throws -> Data {


        print("================================")
        print("CRIANDO START TUYA 3.4")
        print("Nonce original:")
        print(clientNonce.map {String(format:"%02X",$0)}
            .joined(separator:" "))


        var plaintext = Data()


        // nonce 16 bytes
        plaintext.append(clientNonce)


        // bloco extra AES
        plaintext.append(
            Data(
                repeating: 0x00,
                count: 16
            )
        )


        print("START PLAINTEXT:")
        print( plaintext.map {String(format:"%02X",$0)}
            .joined(separator:" "))


        let encrypted = try encryptECB(
            plaintext,
            key: localKey,
            padding: .noPadding
        )
        print("START AES:", encrypted.count, "bytes")
        print(encrypted.map {String(format:"%02X",$0)}
            .joined(separator:" "))

        return makeHandshakeFrame(
            sequence: sequence,
            command: 0x03,
            payload: encrypted,
            key: localKey,
            deviceResponse: false
        )
    }

    // MARK: - Parse Frame

    private struct TuyaFrame {

        let sequence: UInt32
        let command: UInt32
        let length: UInt32
        let retcode: UInt32
        let payload: Data
        let hmac: Data
    }


    private func parseFrame(
        _ data: Data
    ) throws -> TuyaFrame {

        guard data.count >= 20 else {
            throw NovaDigitalError.respostaInvalida
        }

        // =====================================================
        // HEADER
        // =====================================================

        guard data[0] == 0x00,
              data[1] == 0x00,
              data[2] == 0x55,
              data[3] == 0xAA else {

            throw NovaDigitalError.respostaInvalida
        }


        // =====================================================
        // SEQUENCE
        // =====================================================

        let sequence =
            NovaDigitalService.readUInt32BE(
                data,
                offset: 4
            )


        // =====================================================
        // COMMAND
        // =====================================================

        let command =
            NovaDigitalService.readUInt32BE(
                data,
                offset: 8
            )


        // =====================================================
        // LENGTH
        // =====================================================

        let length =
            NovaDigitalService.readUInt32BE(
                data,
                offset: 12
            )

        let totalLength =
            16 + Int(length)

        guard data.count >= totalLength else {

            throw NovaDigitalError.respostaInvalida
        }


        // =====================================================
        // RETCODE
        // =====================================================

        let retcode =
            NovaDigitalService.readUInt32BE(
                data,
                offset: 16
            )


        // =====================================================
        // ESTRUTURA
        //
        // HEADER       16
        // RETCODE       4
        // PAYLOAD       N
        // HMAC         32
        // FOOTER        4
        // =====================================================

        let payloadStart = 20

        let payloadLength =
            Int(length)
            - 4       // retcode
            - 32      // HMAC
            - 4       // footer

        guard payloadLength >= 0 else {

            throw NovaDigitalError.respostaInvalida
        }


        let payloadEnd =
            payloadStart + payloadLength


        guard payloadEnd + 32 + 4 <= data.count else {

            throw NovaDigitalError.respostaInvalida
        }


        // =====================================================
        // PAYLOAD
        // =====================================================

        let payload = Data(
            data[
                payloadStart..<payloadEnd
            ]
        )


        // =====================================================
        // HMAC
        // =====================================================

        let hmacStart = payloadEnd

        let hmacEnd =
            hmacStart + 32

        let hmac = Data(
            data[
                hmacStart..<hmacEnd
            ]
        )


        // =====================================================
        // FOOTER
        // =====================================================

        guard data[hmacEnd] == 0x00,
              data[hmacEnd + 1] == 0x00,
              data[hmacEnd + 2] == 0xAA,
              data[hmacEnd + 3] == 0x55 else {

            throw NovaDigitalError.respostaInvalida
        }


        return TuyaFrame(
            sequence: sequence,
            command: command,
            length: length,
            retcode: retcode,
            payload: payload,
            hmac: hmac
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
    // MARK: - AES ECB

    private func encryptECB(
        _ data: Data,
        key: Data,
        padding: Padding
    ) throws -> Data {

        let aes = try AES(
            key: Array(key),
            blockMode: ECB(),
            padding: padding
        )

        let encrypted = try aes.encrypt(
            Array(data)
        )

        return Data(
            encrypted
        )
    }


    private func decryptECB(
        _ data: Data,
        key: Data
    ) throws -> Data {

        let aes = try AES(
            key: Array(key),
            blockMode: ECB(),
            padding: .noPadding
        )

        let decrypted = try aes.decrypt(
            Array(data)
        )

        return Data(decrypted)
    }
    
    // MARK: - AES Key

    private func makeAESKey(
        from localKey: String
    ) throws -> Data {

        let key = Data(
            localKey.utf8
        )

        guard key.count == 16 else {

            throw NovaDigitalError.localKeyInvalida
        }

        return key
    }


    // MARK: - TCP

    private func connect(
        ip: String
    ) async throws -> NWConnection {

        guard let port = NWEndpoint.Port(
            rawValue: tuyaPort
        ) else {

            throw NovaDigitalError.conexaoFalhou
        }

        let connection = NWConnection(
            host: NWEndpoint.Host(ip),
            port: port,
            using: .tcp
        )

        return try await withCheckedThrowingContinuation {

            (
                continuation:
                CheckedContinuation<
                    NWConnection,
                    Error
                >
            ) in

            let state = ConnectionState(
                continuation: continuation,
                connection: connection
            )

            connection.stateUpdateHandler = {
                [state]
                newState in

                switch newState {

                case .ready:

                    Task {

                        await state.finishSuccess()
                    }

                case .failed(let error):

                    Task {

                        await state.finishFailure(
                            error
                        )
                    }

                case .cancelled:

                    Task {

                        await state.finishFailure(
                            NovaDigitalError.conexaoFalhou
                        )
                    }

                default:

                    break
                }
            }

            connection.start(
                queue:
                    DispatchQueue.global(
                        qos: .userInitiated
                    )
            )
        }
    }


    // MARK: - Send

    private func send(
        _ data: Data,
        connection: NWConnection
    ) async throws {

        try await withCheckedThrowingContinuation {

            (
                continuation:
                CheckedContinuation<
                    Void,
                    Error
                >
            ) in

            connection.send(
                content: data,
                completion: .contentProcessed {
                    error in

                    if let error {

                        continuation.resume(
                            throwing: error
                        )

                    } else {

                        continuation.resume()
                    }
                }
            )
        }
    }

    // MARK: - Receive Tuya Frame

    private func receive(
        connection: NWConnection,
        timeout: TimeInterval = 5
    ) async throws -> Data {

        try await withThrowingTaskGroup(
            of: Data.self
        ) { group in

            group.addTask {

                var buffer = Data()

                while true {

                    let chunk = try await withCheckedThrowingContinuation {
                        (
                            continuation:
                            CheckedContinuation<Data, Error>
                        ) in

                        connection.receive(
                            minimumIncompleteLength: 1,
                            maximumLength: 65535
                        ) { data, _, isComplete, error in

                            if let error {

                                continuation.resume(
                                    throwing: error
                                )

                                return
                            }

                            if let data,
                               !data.isEmpty {

                                continuation.resume(
                                    returning: data
                                )

                                return
                            }

                            if isComplete {

                                continuation.resume(
                                    throwing:
                                        NovaDigitalError.conexaoFalhou
                                )

                                return
                            }

                            continuation.resume(
                                throwing:
                                    NovaDigitalError.respostaInvalida
                            )
                        }
                    }

                    buffer.append(chunk)

                    print(
                        "TCP recebeu:",
                        chunk.count,
                        "bytes"
                    )

                    print(
                        "Buffer:",
                        buffer.count,
                        "bytes"
                    )

                    // ---------------------------------------------
                    // Cabeçalho Tuya 55AA
                    // ---------------------------------------------

                    guard buffer.count >= 16 else {
                        continue
                    }

                    guard buffer[0] == 0x00,
                          buffer[1] == 0x00,
                          buffer[2] == 0x55,
                          buffer[3] == 0xAA else {

                        throw NovaDigitalError.respostaInvalida
                    }

                    // ---------------------------------------------
                    // LENGTH
                    // ---------------------------------------------

                    let length = Int(
                        NovaDigitalService.readUInt32BE(
                            buffer,
                            offset: 12
                        )
                    )

                    let totalLength =
                        16 + length

                    print(
                        "Frame esperado:",
                        totalLength,
                        "bytes"
                    )

                    // Ainda não recebemos o frame inteiro.

                    if buffer.count < totalLength {
                        continue
                    }

                    // ---------------------------------------------
                    // FRAME COMPLETO
                    // ---------------------------------------------

                    let frame = Data(
                        buffer[
                            0..<totalLength
                        ]
                    )

                    print(
                        "FRAME TUYA COMPLETO:",
                        frame.count,
                        "bytes"
                    )

                    print(
                        frame
                            .map {
                                String(
                                    format: "%02X",
                                    $0
                                )
                            }
                            .joined(
                                separator: " "
                            )
                    )

                    return frame
                }
            }

            // ---------------------------------------------
            // TIMEOUT
            // ---------------------------------------------

            group.addTask {

                try await Task.sleep(
                    for:
                        .seconds(
                            timeout
                        )
                )

                throw NovaDigitalError.timeout
            }

            let result = try await group.next()!

            group.cancelAll()

            return result
        }
    }
    // MARK: - Sequence

    private func nextSequence() -> UInt32 {

        sequence &+= 1

        if sequence == 0 {

            sequence = 1
        }

        return sequence
    }


    // MARK: - UInt32 Big Endian

    private func uint32BE(
        _ value: UInt32
    ) -> Data {

        Data([
            UInt8(
                (value >> 24) & 0xFF
            ),

            UInt8(
                (value >> 16) & 0xFF
            ),

            UInt8(
                (value >> 8) & 0xFF
            ),

            UInt8(
                value & 0xFF
            )
        ])
    }


    private nonisolated static func readUInt32BE(
        _ data: Data,
        offset: Int
    ) -> UInt32 {

        UInt32(data[offset]) << 24
        |
        UInt32(data[offset + 1]) << 16
        |
        UInt32(data[offset + 2]) << 8
        |
        UInt32(data[offset + 3])
    }

    // MARK: - Ping

    func ping(
        device: Device
    ) async -> Bool {

        guard let ip = device.ip else {

            return false
        }

        do {

            let connection = try await connect(
                ip: ip
            )

            connection.cancel()

            return true

        } catch {

            return false
        }
    }
}


// MARK: - Connection State

private actor ConnectionState {

    private var continuation:
        CheckedContinuation<
            NWConnection,
            Error
        >?

    private var finished = false

    private let connection: NWConnection

    init(
        continuation:
            CheckedContinuation<
                NWConnection,
                Error
        >,
        connection: NWConnection
    ) {

        self.continuation = continuation

        self.connection = connection
    }


    func finishSuccess() {

        guard !finished,
              let continuation else {

            return
        }

        finished = true

        self.continuation = nil

        continuation.resume(
            returning: connection
        )
    }


    func finishFailure(
        _ error: Error
    ) {

        guard !finished,
              let continuation else {

            return
        }

        finished = true

        self.continuation = nil

        continuation.resume(
            throwing: error
        )
    }
}


// MARK: - Erros

enum NovaDigitalError: LocalizedError {

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

            return
                "O dispositivo não possui um endereço IP."


        case .localKeyAusente:

            return
                "A Local Key não foi configurada."


        case .localKeyInvalida:

            return
                "A Local Key deve possuir 16 caracteres."


        case .conexaoFalhou:

            return
                "Não foi possível conectar ao dispositivo."


        case .handshakeFalhou:

            return
                "Falha no handshake Tuya 3.4."


        case .respostaInvalida:

            return
                "Resposta inválida do dispositivo."


        case .deviceIDAusente:

            return
                "O dispositivo não possui Device ID."


        case .timeout:

            return
                "Tempo limite aguardando resposta do dispositivo."
        }
    }
}
