//
//  TuyaCloudService.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 13/08/26.
//
import Foundation
import CryptoKit


struct TuyaTokenResponse: Codable {

    let success: Bool
    let result: TokenResult?
    let code: Int?
    let msg: String?

}


struct TokenResult: Codable {

    let accessToken: String
    let expireTime: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expireTime = "expire_time"
    }
}

final class TuyaCloudService {


    static let shared = TuyaCloudService()


    private init(){}



    private let baseURL =
    "https://openapi.tuyaus.com"


    private let accessID =
    "req3suwf35rr4qj4gtvn"


    private let accessSecret =
    "82b8c17e5c9e46f8b6fc024fa90c0c1d"



    private var token: String?
  

    // MARK: - Assinatura Tuya
    

    private func makeSign(
        method: String,
        path: String,
        body: String,
        timestamp: String,
        nonce: String,
        token: String? = nil
    ) -> String {

        let contentHash = SHA256
            .hash(
                data: body.data(using: .utf8) ?? Data()
            )
            .map {
                String(format: "%02x", $0)
            }
            .joined()

        let stringToSign =
            """
            \(method)
            \(contentHash)

            \(path)
            """

        let signString: String

        if let token {

            signString =
                accessID
                + token
                + timestamp
                + nonce
                + stringToSign

        } else {

            signString =
                accessID
                + timestamp
                + nonce
                + stringToSign
        }

        let key = SymmetricKey(
            data: accessSecret.data(using: .utf8)!
        )

        let hmac =
            HMAC<SHA256>.authenticationCode(
                for: signString.data(using: .utf8)!,
                using: key
            )

        return hmac
            .map {
                String(format: "%02X", $0)
            }
            .joined()
    }
    
    // MARK: - Buscar Token

    func getToken() async throws -> String {

        let path = "/v1.0/token?grant_type=1"

        let timestamp =
            String(
                Int(Date().timeIntervalSince1970 * 1000)
            )

        let nonce =
            UUID()
                .uuidString
                .replacingOccurrences(
                    of: "-",
                    with: ""
                )

        let sign = makeSign(
            method: "GET",
            path: path,
            body: "",
            timestamp: timestamp,
            nonce: nonce
        )

        var request = URLRequest(
            url: URL(
                string: baseURL + path
            )!
        )

        request.httpMethod = "GET"

        request.setValue(
            accessID,
            forHTTPHeaderField: "client_id"
        )

        request.setValue(
            timestamp,
            forHTTPHeaderField: "t"
        )

        request.setValue(
            nonce,
            forHTTPHeaderField: "nonce"
        )

        request.setValue(
            sign,
            forHTTPHeaderField: "sign"
        )

        request.setValue(
            "HMAC-SHA256",
            forHTTPHeaderField: "sign_method"
        )

        let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

        print("==============================")
        print("TUYA TOKEN")
        print("HTTP:", response)
        print(
            String(
                data: data,
                encoding: .utf8
            ) ?? "SEM JSON"
        )
        print("==============================")

        let result =
            try JSONDecoder()
                .decode(
                    TuyaTokenResponse.self,
                    from: data
                )

        guard
            result.success,
            let accessToken = result.result?.accessToken
        else {

            print("TUYA ERRO:")
            print("CODE:", result.code ?? 0)
            print("MSG:", result.msg ?? "")

            throw NSError(
                domain: "Tuya",
                code: result.code ?? 1
            )
        }

        self.token = accessToken

        print("✅ TOKEN TUYA OBTIDO")

        return accessToken
    }

    // MARK: - Enviar comando


    func sendCommand(
        deviceID:String,
        state:Bool
    ) async throws {


        let accessToken =
        try await getToken()



        let path =
        "/v1.0/iot-03/devices/\(deviceID)/commands"



        let body =
        """
        {
          "commands":[
            {
              "code":"switch_1",
              "value":\(state)
            }
          ]
        }
        """



        let timestamp =
        String(
            Int(Date().timeIntervalSince1970 * 1000)
        )



        let nonce =
            UUID()
                .uuidString
                .replacingOccurrences(
                    of: "-",
                    with: ""
                )

        let sign = makeSign(
            method: "POST",
            path: path,
            body: body,
            timestamp: timestamp,
            nonce: nonce,
            token: accessToken
        )


        var request =
        URLRequest(
            url:
                URL(
                    string:
                    baseURL + path
                )!
        )


        request.httpMethod = "POST"


        request.httpBody =
        body.data(using:.utf8)


        request.setValue(
            "application/json",
            forHTTPHeaderField:"Content-Type"
        )


        request.setValue(
            accessID,
            forHTTPHeaderField:"client_id"
        )


        request.setValue(
            accessToken,
            forHTTPHeaderField:"access_token"
        )


        request.setValue(
            timestamp,
            forHTTPHeaderField:"t"
        )


        request.setValue(
            sign,
            forHTTPHeaderField:"sign"
        )


        request.setValue(
            "HMAC-SHA256",
            forHTTPHeaderField: "sign_method"
        )
        
        request.setValue(
            nonce,
            forHTTPHeaderField: "nonce"
        )

        let (data, response) =
            try await URLSession.shared.data(
                for: request
            )

        print("==============================")
        print("TUYA COMMAND RESPONSE")
        print("HTTP:", response)

        print(
            String(
                data: data,
                encoding: .utf8
            ) ?? "SEM JSON"
        )

        print("==============================")
        
        
//        let (_, response) =
//        try await URLSession.shared.data(
//            for:request
//        )
//
//
//        print(
//            "TUYA RESPONSE:",
//            response
//        )
    }



}
