//
//  TuyaFrame.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 12/08/26.
//
//
//Aqui fica:
//55AA
//length
//sequence
//command
//HMAC
//

import Foundation
import CryptoKit


final class TuyaFrame {


    static let shared = TuyaFrame()


    private init(){}



    enum HMACMode {

        case payload
        case handshakeStart
        case fullFrame
    }


    struct ParsedFrame {

        let sequence: UInt32
        let command: UInt32
        let length: UInt32
        let retcode: UInt32
        let payload: Data
        let hmac: Data
    }
    
    // MARK: - Criar Frame 55AA


    func makeFrame(
        sequence: UInt32,
        command: UInt32,
        payload: Data,
        key: Data,
        hmacMode: HMACMode = .fullFrame
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


        let length = UInt32(
            payload.count
            + 32
            + 4
        )


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


        frame.append(payload)



        let hmacData: Data


        switch hmacMode {

        case .payload:

            hmacData = payload


        case .fullFrame:

            hmacData = frame


        case .handshakeStart:

            var temp = Data()

            temp.append(
                uint32BE(command)
            )

            temp.append(payload)

            hmacData = temp
        }

        print("================================")
        print("HMAC CALCULADO")
        print("MODE:", hmacMode)
        print("HMAC DATA SIZE:", hmacData.count)
        print(hmacData.map {String(format:"%02X",$0)}
            .joined(separator:" "))
        print("================================")
        print("HMAC MODE:", hmacMode)
        print("HMAC DATA SIZE:", hmacData.count)
        
        
        let hmac = Data(
            HMAC<SHA256>.authenticationCode(
                for: hmacData,
                using: SymmetricKey(data:key)
            )
        )


        frame.append(hmac)

        frame.append(footer)


        return frame
    }





    // MARK: - Frame Handshake


    func makeHandshakeFrame(
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



        let retcodeLength = deviceResponse ? 4 : 0


        let length = UInt32(
            retcodeLength
            + payload.count
            + 32
            + 4
        )


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



        if deviceResponse {

            frame.append(
                uint32BE(0)
            )
        }



        frame.append(payload)


        print("================================")
        print("HMAC HANDSHAKE FRAME")
        print("SIZE:", frame.count)
        print(frame.map {String(format:"%02X",$0)}
            .joined(separator:" "))
        print("================================")
        print("HMAC HANDSHAKE FRAME SIZE:", frame.count)

        let hmac = Data(
            HMAC<SHA256>.authenticationCode(
                for: frame,
                using: SymmetricKey(data:key)
            )
        )
        
        print("HMAC RESULT:")
        print(hmac.map {String(format:"%02X",$0)}
            .joined(separator:" "))

        frame.append(hmac)

        frame.append(footer)


        return frame
    }

    // MARK: - Parse
    
    func parse(
        _ data: Data
    ) throws -> ParsedFrame {
        
        guard data.count >= 20 else {

            throw NovaDigitalError.respostaInvalida
        }


        // HEADER 00 00 55 AA

        guard data[0] == 0x00,
              data[1] == 0x00,
              data[2] == 0x55,
              data[3] == 0xAA else {

            throw NovaDigitalError.respostaInvalida
        }



        let sequence =
        TuyaFrame.readUInt32BE(
            data,
            offset: 4
        )


        let command =
        TuyaFrame.readUInt32BE(
            data,
            offset: 8
        )


        let length =
        TuyaFrame.readUInt32BE(
            data,
            offset: 12
        )



        let retcode =
        TuyaFrame.readUInt32BE(
            data,
            offset: 16
        )



        let payloadStart = 20


        let payloadLength =
            Int(length)
            - 4
            - 32
            - 4



        guard payloadLength >= 0 else {

            throw NovaDigitalError.respostaInvalida
        }



        let payloadEnd =
            payloadStart + payloadLength



        guard payloadEnd + 36 <= data.count else {

            throw NovaDigitalError.respostaInvalida
        }



        let payload = Data(
            data[payloadStart..<payloadEnd]
        )



        let hmac = Data(
            data[payloadEnd..<payloadEnd + 32]
        )



        return ParsedFrame(
            sequence: sequence,
            command: command,
            length: length,
            retcode: retcode,
            payload: payload,
            hmac: hmac
        )
    }


    // MARK: - UInt32 BE


    func uint32BE(
        _ value: UInt32
    ) -> Data {


        Data([

            UInt8((value >> 24) & 0xff),

            UInt8((value >> 16) & 0xff),

            UInt8((value >> 8) & 0xff),

            UInt8(value & 0xff)

        ])
    }




    nonisolated static func readUInt32BE(
        _ data: Data,
        offset: Int
    ) -> UInt32 {


        UInt32(data[offset]) << 24 |
        UInt32(data[offset + 1]) << 16 |
        UInt32(data[offset + 2]) << 8 |
        UInt32(data[offset + 3])
    }

}
