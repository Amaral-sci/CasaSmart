//
//  TuyaCrypto.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 12/08/26.
//

import Foundation
import CryptoKit
import CryptoSwift


final class TuyaCrypto {


    static let shared = TuyaCrypto()


    private init() {}



    // MARK: - AES KEY

    func makeAESKey(
        from localKey: String
    ) throws -> Data {


        let key = Data(localKey.utf8)


        guard key.count == 16 else {

            throw NovaDigitalError.localKeyInvalida
        }


        return key
    }



    // MARK: - AES ECB


    func encryptECB(
        _ data: Data,
        key: Data,
        padding: Padding
    ) throws -> Data {


        let aes = try AES(
            key: Array(key),
            blockMode: ECB(),
            padding: padding
        )


        return Data(
            try aes.encrypt(
                Array(data)
            )
        )
    }



    func decryptECB(
        _ data: Data,
        key: Data
    ) throws -> Data {


        let aes = try AES(
            key: Array(key),
            blockMode: ECB(),
            padding: .noPadding
        )


        return Data(
            try aes.decrypt(
                Array(data)
            )
        )
    }



    // MARK: - HMAC


    func hmacSHA256(
        data: Data,
        key: Data
    ) -> Data {


        Data(
            HMAC<SHA256>.authenticationCode(
                for: data,
                using: SymmetricKey(data:key)
            )
        )
    }



    // MARK: - Session Key


    func createSessionKey(
        localKey: Data,
        clientNonce: Data,
        deviceNonce: Data
    ) -> Data {


        var buffer = Data()


        buffer.append(localKey)

        buffer.append(clientNonce)

        buffer.append(deviceNonce)



        return Data(
            SHA256.hash(
                data: buffer
            )
        )
    }

}
