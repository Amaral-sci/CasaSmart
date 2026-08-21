//
//  TuyaCloudService.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 13/08/26.
//

import Foundation
import CryptoKit


// MARK: - Models

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




// MARK: - Status

struct TuyaStatusResponse: Codable {

    let success: Bool
    let result: [TuyaStatus]

}

struct TuyaStatus: Codable {

    let code: String
    let value: AnyCodable

}
struct AnyCodable: Codable {


    let value: Any


    init(from decoder: Decoder) throws {

        let container =
        try decoder.singleValueContainer()


        if let bool =
            try? container.decode(Bool.self) {

            value = bool
            return
        }


        if let int =
            try? container.decode(Int.self) {

            value = int
            return
        }


        if let string =
            try? container.decode(String.self) {

            value = string
            return
        }


        value = ""
    }


    func encode(
        to encoder: Encoder
    ) throws {

    }
}

struct TuyaStatusItem: Codable {

    let code: String
    let value: Bool?

}



// MARK: - Service

final class TuyaCloudService {


    static let shared = TuyaCloudService()


    private init(){}



    private let baseURL =
    "https://openapi.tuyaus.com"



    private let accessID =
    "req3suwf35rr4qj4gtvn"



    private let accessSecret =
    "82b8c17e5c9e46f8b6fc024fa90c0c1d"



    private var token:String?



    // MARK: SIGN


    private func makeSign(
        method:String,
        path:String,
        body:String,
        timestamp:String,
        token:String? = nil
    )
    -> String {


        let bodyHash =
        SHA256.hash(
            data:
                body.data(using:.utf8) ?? Data()
        )
        .map {

            String(
                format:"%02x",
                $0
            )

        }
        .joined()



        let stringToSign =
        """
        \(method)
        \(bodyHash)

        \(path)
        """



        var signString = ""


        if let token {


            signString =
            accessID
            +
            token
            +
            timestamp
            +
            stringToSign


        } else {


            signString =
            accessID
            +
            timestamp
            +
            stringToSign
        }



        let key =
        SymmetricKey(
            data:
                accessSecret.data(using:.utf8)!
        )



        let hmac =
        HMAC<SHA256>.authenticationCode(
            for:
                signString.data(using:.utf8)!,
            using:key
        )



        return hmac
            .map {

                String(
                    format:"%02X",
                    $0
                )

            }
            .joined()
    }







    // MARK: TOKEN


    func getToken()
    async throws
    -> String {


        let path =
        "/v1.0/token?grant_type=1"



        let timestamp =
        String(
            Int(
                Date()
                .timeIntervalSince1970
                *
                1000
            )
        )



        let sign =
        makeSign(
            method:"GET",
            path:path,
            body:"",
            timestamp:timestamp
        )



        var request =
        URLRequest(
            url:
                URL(
                    string:
                        baseURL + path
                )!
        )



        request.httpMethod = "GET"



        request.setValue(
            accessID,
            forHTTPHeaderField:
                "client_id"
        )


        request.setValue(
            timestamp,
            forHTTPHeaderField:
                "t"
        )


        request.setValue(
            sign,
            forHTTPHeaderField:
                "sign"
        )


        request.setValue(
            "HMAC-SHA256",
            forHTTPHeaderField:
                "sign_method"
        )



        let (data,response) =
        try await URLSession.shared.data(
            for:request
        )



        print("======================")
        print("TUYA TOKEN RESPONSE")

        print(
            (response as? HTTPURLResponse)?
                .statusCode ?? 0
        )


        print(
            String(
                data:data,
                encoding:.utf8
            ) ?? ""
        )

        print("======================")



        let decoded =
        try JSONDecoder()
            .decode(
                TuyaTokenResponse.self,
                from:data
            )



        guard
            decoded.success,
            let token =
                decoded.result?.accessToken

        else {

            throw NSError(
                domain:"TUYA TOKEN ERROR",
                code:1
            )
        }



        self.token = token



        print("TOKEN OK")



        return token
    }







    // MARK: STATUS


    func getStatus(
        deviceID:String
    ) async throws -> Bool {



        let token =
        try await getToken()



        let path =
        "/v1.0/devices/\(deviceID)/status"



        let timestamp =
        String(
            Int(
                Date()
                .timeIntervalSince1970
                *
                1000
            )
        )



        let sign =
        makeSign(
            method:"GET",
            path:path,
            body:"",
            timestamp:timestamp,
            token:token
        )



        var request =
        URLRequest(
            url:
                URL(
                    string:
                        baseURL + path
                )!
        )



        request.httpMethod = "GET"



        addHeaders(
            request:&request,
            token:token,
            timestamp:timestamp,
            sign:sign
        )



        let (data,_) =
        try await URLSession.shared.data(
            for:request
        )



        print("======================")
        print("TUYA STATUS")

        print(
            String(
                data:data,
                encoding:.utf8
            ) ?? ""
        )

        print("======================")
        
        let response =
        try JSONDecoder()
            .decode(
                TuyaStatusResponse.self,
                from:data
            )


        guard
            let state =
                response.result.first(where:{
                    $0.code == "switch_1"
                })
        else {

            throw NSError(
                domain:"Tuya",
                code:500
            )
        }


        return state.value.value as? Bool ?? false
    }







    // MARK: COMMAND


    func sendCommand(
        deviceID:String,
        state:Bool
    )
    async throws {



        let token =
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
            Int(
                Date()
                .timeIntervalSince1970
                *
                1000
            )
        )



        let sign =
        makeSign(
            method:"POST",
            path:path,
            body:body,
            timestamp:timestamp,
            token:token
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
            forHTTPHeaderField:
                "Content-Type"
        )



        addHeaders(
            request:&request,
            token:token,
            timestamp:timestamp,
            sign:sign
        )



        let (data,response) =
        try await URLSession.shared.data(
            for:request
        )



        print("======================")
        print("TUYA COMMAND")

        print(
            (response as? HTTPURLResponse)?
                .statusCode ?? 0
        )


        print(
            String(
                data:data,
                encoding:.utf8
            ) ?? ""
        )

        print("======================")
    }







    private func addHeaders(
        request:inout URLRequest,
        token:String,
        timestamp:String,
        sign:String
    ){


        request.setValue(
            accessID,
            forHTTPHeaderField:
                "client_id"
        )


        request.setValue(
            token,
            forHTTPHeaderField:
                "access_token"
        )


        request.setValue(
            timestamp,
            forHTTPHeaderField:
                "t"
        )


        request.setValue(
            sign,
            forHTTPHeaderField:
                "sign"
        )


        request.setValue(
            "HMAC-SHA256",
            forHTTPHeaderField:
                "sign_method"
        )
    }
}
