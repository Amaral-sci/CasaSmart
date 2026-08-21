//
//  TuyaHandshake.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 12/08/26.
//
import Foundation
import Network
import CryptoKit
import CryptoSwift

// MARK: - Handshake Tuya 3.4



final class TuyaHandshake {
    
    static let shared = TuyaHandshake()
    
    private init() {}
    
    func performHandshake(
        connection: NWConnection,
        localKey: Data
    ) async throws -> Data {
        
        print("LOCAL KEY HEX")
        print(localKey.map {String(format:"%02X",$0)}
            .joined(separator:" "))
        print("SIZE:", localKey.count)
        print("================================")
        
        // 1. CLIENT NONCE
        
        var clientNonce = Data()
        
        for _ in 0..<16 {clientNonce.append(UInt8.random(in: 0...255))}
        
        print("Client nonce criado")
        print("Client nonce:",clientNonce.map {String(format: "%02X", $0)}
            .joined(separator: " "))
        
        
        // =====================================================
        // 2. START 0x03
        // =====================================================
        
    //    let startSequence: UInt32 = 0
        let startSequence = UInt32.random( in: 1...UInt32.max )
        
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
        
        try await TuyaTCPClient.shared.send(startPacket,connection: connection)
        print("START (0x03) enviado")
        
        
        // =====================================================
        // 3. RECEBER RESPOSTA
        // =====================================================
        
        let responsePacket = try await TuyaTCPClient.shared.receive(connection: connection)
        print("================================")
        print("TUYA RESPONSE RAW")
        print( "Bytes:", responsePacket.count)
        print( responsePacket.map {String(format: "%02X", $0)}
            .joined(separator: " "))
        print("================================")
        
        
        // =====================================================
        // 4. PARSE
        // =====================================================
        
        let response = try TuyaFrame.shared.parse(responsePacket)
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
        
        let decryptedResponse = try TuyaCrypto.shared.decryptECB(response.payload, key: localKey)
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
        
        
        
        
        let authKey = Data( HMAC<SHA256>.authenticationCode( for: Data("3.4".utf8), using: SymmetricKey(data: localKey)))
        
        
        // NOVO TESTE
        let hashedLocalKey = Data(SHA256.hash( data: localKey))
        
        
        let keys = [
            
            ("LOCAL KEY", localKey),
            
            ("SHA256 LOCAL KEY", hashedLocalKey),
            
            ("AUTH KEY", authKey)
            
        ]
        
        let deviceNonceASCII = Data(
            String(
                data: deviceNonce,
                encoding: .utf8
            )!.utf8
        )
        
        
        let messages = [
            
            ("3.4 + client + device",
             Data("3.4".utf8)
             + clientNonce
             + deviceNonce),
            
            
            ("3.4 + client + device ASCII",
             Data("3.4".utf8)
             + clientNonce
             + deviceNonceASCII),
            
            
            ("3.4 + device + client",
             Data("3.4".utf8)
             + deviceNonce
             + clientNonce),
            
            
            ("client + device",
             clientNonce
             + deviceNonce),
            
            
            ("device + client",
             deviceNonce
             + clientNonce)
            
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
        
        let encryptedFinish = try TuyaCrypto.shared.encryptECB(finishHMAC, key: localKey, padding: .noPadding)
       
  //      let finishSequence: UInt32 = 1
        let finishSequence = UInt32.random( in: 1...UInt32.max )
        
        let finishPacket = TuyaFrame.shared.makeHandshakeFrame(
            sequence: finishSequence,
            command: 0x05,
            payload: encryptedFinish,
            key: localKey,
            deviceResponse: false,
            hmacMode: .payload

        )
        
        print("================================")
        print("TUYA FINISH")
        print("Sequence:",finishSequence)
        print("Command: 0x05")
        print("Payload:",encryptedFinish.count,"bytes")
        print("Frame:",finishPacket.count,"bytes")
        print("================================")
        
        try await TuyaTCPClient.shared.send(finishPacket,connection: connection)
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
        
        print("================================")
        print("SESSION KEY CRIADA")
        print(sessionKey.map {String(format: "%02X", $0)}
                .joined(separator: " "))
        print("================================")
        
        return sessionKey
    }
    
    // MARK: - START Packet 0x03

    private func makeHandshakeStartPacket(
        sequence: UInt32,
        clientNonce: Data,
        localKey: Data
    ) throws -> Data {


        print("================================")
        print("CRIANDO START TUYA 3.4")
        print("Nonce:")
        print( clientNonce.map {String(format:"%02X",$0)}
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
        print("================================")
        print("START PLAINTEXT")
        print("SIZE:", plaintext.count)
        print(plaintext.map {String(format:"%02X",$0)}
            .joined(separator:" "))
        print("================================")

        let encrypted = try TuyaCrypto.shared.encryptECB(plaintext, key: localKey,            padding: .noPadding)

        print("AES PAYLOAD REAL:", encrypted.count)
        print("START AES:",encrypted.count,"bytes")


        let frame = TuyaFrame.shared.makeHandshakeFrame(
            sequence: sequence,
            command: 0x03,
            payload: encrypted,
            key: localKey,
            deviceResponse: false,
            hmacMode: .handshakeStart
        )
        return frame
    }
}
