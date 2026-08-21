//
//  NetworkScanner.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//

import Foundation
import Combine
import Darwin
import CryptoKit
import CryptoSwift

@MainActor
final class NetworkScanner: ObservableObject {

    // MARK: - Estado

    @Published
    var devices: [NetworkDevice] = []

    @Published
    var scanning = false


    // MARK: - Portas Tuya

    private let discoveryPorts: [UInt16] = [
        6666,
        6667
    ]


    // MARK: - Sockets

    private var sockets: [Int32: Int32] = [:]

    private var receiveSources: [
        Int32: DispatchSourceRead
    ] = [:]


    // MARK: - Scan

    func scan() {

        stop()

        devices.removeAll()

        scanning = true

        print("")
        print("==============================")
        print("🔎 TUYA NETWORK SCANNER")
        print("==============================")
        print("Iniciando descoberta UDP...")
        print("Portas:", discoveryPorts)
        print("==============================")


        for port in discoveryPorts {

            startSocket(
                port: port
            )
        }


        // Mantém o scanner ativo por alguns segundos.
        Task { @MainActor in

            try? await Task.sleep(
                for: .seconds(10)
            )

            guard scanning else {
                return
            }

            print("")
            print("==============================")
            print("🔎 FIM DA BUSCA")
            print("Dispositivos encontrados:", devices.count)
            print("==============================")


            scanning = false
        }
    }


    // MARK: - Criar Socket UDP

    private func startSocket(
        port: UInt16
    ) {

        let socketFD =
            socket(
                AF_INET,
                SOCK_DGRAM,
                IPPROTO_UDP
            )


        guard socketFD >= 0 else {

            print(
                "❌ Não foi possível criar socket UDP:",
                port
            )

            return
        }


        // Permite reutilizar a porta.
        var reuse: Int32 = 1

        let reuseResult =
            setsockopt(
                socketFD,
                SOL_SOCKET,
                SO_REUSEADDR,
                &reuse,
                socklen_t(
                    MemoryLayout<Int32>.size
                )
            )


        guard reuseResult == 0 else {

            print(
                "❌ SO_REUSEADDR falhou:",
                port
            )

            close(socketFD)

            return
        }


        // Permite broadcast.
        var broadcast: Int32 = 1

        let broadcastResult =
            setsockopt(
                socketFD,
                SOL_SOCKET,
                SO_BROADCAST,
                &broadcast,
                socklen_t(
                    MemoryLayout<Int32>.size
                )
            )


        guard broadcastResult == 0 else {

            print(
                "❌ SO_BROADCAST falhou:",
                port
            )

            close(socketFD)

            return
        }


        // Bind 0.0.0.0:porta

        var address =
            sockaddr_in()

        address.sin_len =
            UInt8(
                MemoryLayout<sockaddr_in>.size
            )

        address.sin_family =
            sa_family_t(AF_INET)

        address.sin_port =
            port.bigEndian

        address.sin_addr =
            in_addr(
                s_addr: INADDR_ANY
            )


        let bindResult =
            withUnsafePointer(
                to: &address
            ) {

                $0.withMemoryRebound(
                    to: sockaddr.self,
                    capacity: 1
                ) {

                    bind(
                        socketFD,
                        $0,
                        socklen_t(
                            MemoryLayout<sockaddr_in>.size
                        )
                    )
                }
            }


        guard bindResult == 0 else {

            print(
                "❌ Não foi possível fazer bind UDP:",
                port,
                "erro:",
                errno
            )

            close(socketFD)

            return
        }


        sockets[Int32(port)] =
            socketFD


        print(
            "🟢 UDP \(port) aguardando dispositivos..."
        )


        let source = makeReceiveSource(
            socketFD: socketFD,
            port: port
        )

        receiveSources[socketFD] = source

        source.resume()


        // Envia um broadcast simples para acordar
        // dispositivos que aceitam descoberta ativa.

        sendBroadcast(
            socketFD: socketFD,
            port: port
        )
        
    }

    
    
    // MARK: - Receive Source

   
    private nonisolated func makeReceiveSource(
        socketFD: Int32,
        port: UInt16
    ) -> DispatchSourceRead {

        let queue = DispatchQueue(
            label: "com.csmart.tuya.receive.\(port)",
            qos: .userInitiated
        )

        let source = DispatchSource.makeReadSource(
            fileDescriptor: socketFD,
            queue: queue
        )

        source.setEventHandler { [weak self] in

            guard self != nil else {
                return
            }

            var buffer = [UInt8](
                repeating: 0,
                count: 65535
            )

            var sender = sockaddr_storage()

            var senderLength = socklen_t(
                MemoryLayout<sockaddr_storage>.size
            )

            let received = withUnsafeMutablePointer(
                to: &sender
            ) {

                $0.withMemoryRebound(
                    to: sockaddr.self,
                    capacity: 1
                ) {

                    recvfrom(
                        socketFD,
                        &buffer,
                        buffer.count,
                        MSG_DONTWAIT,
                        $0,
                        &senderLength
                    )
                }
            }

            guard received > 0 else {
                return
            }

            let data = Data(
                buffer.prefix(Int(received))
            )

            let remoteIP = Self.ipAddress(
                from: sender
            )

            Task { @MainActor [weak self] in

                guard let self else {
                    return
                }

                guard self.scanning else {
                    return
                }

                self.processPacket(
                    data,
                    port: port,
                    remoteIP: remoteIP
                )
            }
        }

        source.setCancelHandler {
            close(socketFD)
        }

        return source
    }


    // MARK: - Broadcast

    private func sendBroadcast(
        socketFD: Int32,
        port: UInt16
    ) {

        let message =
            makeDiscoveryPacket()


        var destination =
            sockaddr_in()

        destination.sin_len =
            UInt8(
                MemoryLayout<sockaddr_in>.size
            )

        destination.sin_family =
            sa_family_t(AF_INET)

        destination.sin_port =
            port.bigEndian

        destination.sin_addr =
            in_addr(
                s_addr:
                    UInt32(
                        0xFFFFFFFF
                    )
            )


        let result =
            message.withUnsafeBytes { bytes in

                withUnsafePointer(
                    to: &destination
                ) {

                    $0.withMemoryRebound(
                        to: sockaddr.self,
                        capacity: 1
                        )
                    {

                        sendto(
                            socketFD,
                            bytes.baseAddress,
                            message.count,
                            0,
                            $0,
                            socklen_t(
                                MemoryLayout<sockaddr_in>.size
                            )
                        )
                    }
                }
            }


        if result >= 0 {

            print(
                "📢 Broadcast Tuya enviado →",
                port
            )

        } else {

            print(
                "❌ Falha enviando broadcast →",
                port,
                "errno:",
                errno
            )
        }
    }


    // MARK: - Pacote Discovery

    private func makeDiscoveryPacket()
        -> Data {

        /*
         Tuya discovery utiliza frames UDP
         próprios.

         Para a primeira etapa do scanner,
         o principal objetivo é manter o socket
         aberto nas portas 6666/6667 e receber
         os broadcasts dos dispositivos.

         O pacote abaixo é um frame 55AA mínimo.
        */


        var packet =
            Data()


        packet.append(
            contentsOf: [
                0x00,
                0x00,
                0x55,
                0xAA
            ]
        )


        // Sequence

        packet.append(
            contentsOf: [
                0x00,
                0x00,
                0x00,
                0x01
            ]
        )


        // Command

        packet.append(
            contentsOf: [
                0x00,
                0x00,
                0x00,
                0x0A
            ]
        )


        // Length

        packet.append(
            contentsOf: [
                0x00,
                0x00,
                0x00,
                0x08
            ]
        )


        // Payload vazio + CRC placeholder

        packet.append(
            contentsOf: [
                0x00,
                0x00,
                0x00,
                0x00
            ]
        )


        packet.append(
            contentsOf: [
                0x00,
                0x00,
                0x00,
                0x00
            ]
        )


        // Footer

        packet.append(
            contentsOf: [
                0x00,
                0x00,
                0xAA,
                0x55
            ]
        )


        return packet
    }


    // MARK: - Processar pacote

    private func processPacket(
        _ data: Data,
        port: UInt16,
        remoteIP: String?
    ) {

        print("")
        print("==============================")
        print("📡 PACOTE UDP RECEBIDO")
        print("==============================")
        print("Porta:", port)
        print("IP:", remoteIP ?? "-")
        print("Bytes:", data.count)


        print(
            "HEX:",
            data.map {
                String(
                    format: "%02X",
                    $0
                )
            }
            .joined(
                separator: " "
            )
        )


        // JSON direto

        if let json =
            decodeJSON(data) {

            handleTuyaJSON(
                json,
                port: port,
                remoteIP: remoteIP
            )

            return
        }


        // 55AA

        if let payload =
            extract55AAPayload(
                data,
                port: port
            ) {

            print(
                "📦 Payload 55AA:",
                payload.count,
                "bytes"
            )


            // JSON puro

            if let json =
                decodeJSON(payload) {

                handleTuyaJSON(
                    json,
                    port: port,
                    remoteIP: remoteIP
                )

                return
            }


            // Tenta AES Discovery

            if let decrypted =
                decryptTuyaDiscovery(
                    payload
                ) {

                if let json =
                    decodeJSON(
                        decrypted
                    ) {

                    handleTuyaJSON(
                        json,
                        port: port,
                        remoteIP: remoteIP
                    )

                    return
                }
            }
        }


        print(
            "⚠️ Pacote UDP não reconhecido"
        )

        print("==============================")
    }


    // MARK: - Extrair Payload 55AA

    private func extract55AAPayload(
        _ data: Data,
        port: UInt16
    ) -> Data? {

        guard data.count >= 24 else {
            return nil
        }


        let bytes =
            [UInt8](data)


        guard
            bytes[0] == 0x00,
            bytes[1] == 0x00,
            bytes[2] == 0x55,
            bytes[3] == 0xAA
        else {

            return nil
        }


        /*
         Header:

         0...3   prefix
         4...7   sequence
         8...11  command
         12...15 length
         16...   payload
        */

        let payloadStart =
            port == 6667 ? 20 : 16

        let payloadEnd =
            data.count - 8


        guard
            payloadEnd > payloadStart,
            payloadEnd <= data.count
        else {

            return nil
        }


        return Data(
            data[
                payloadStart..<payloadEnd
            ]
        )
    }


    // MARK: - AES Discovery

    private func decryptTuyaDiscovery(
        _ data: Data
    ) -> Data? {

        do {

            let keySource =
                Data(
                    "yGAdlopoPVldABfn"
                        .utf8
                )


            let md5 =
                Insecure.MD5
                    .hash(
                        data: keySource
                    )


            let key =
                Array(md5)


            let aes =
                try AES(
                    key: key,
                    blockMode: ECB(),
                    padding: .noPadding
                )


            let decrypted =
                try aes.decrypt(
                    Array(data)
                )


            let result =
                Data(decrypted)


            print("")
            print("🔓 AES DISCOVERY DESCRIPTOU")
            print(
                String(
                    data: result,
                    encoding: .utf8
                )
                ?? "binário"
            )


            return result

        }
        catch {

            print(
                "❌ AES discovery erro:",
                error
            )

            return nil
        }
    }


    // MARK: - JSON

    private func decodeJSON(
        _ data: Data
    ) -> [String: Any]? {

        guard
            let object =
                try? JSONSerialization.jsonObject(
                    with: data,
                    options: []
                )
        else {

            return nil
        }


        return object as? [String: Any]
    }


    // MARK: - Tuya JSON

    private func handleTuyaJSON(
        _ json: [String: Any],
        port: UInt16,
        remoteIP: String?
    ) {

        print("")
        print("==============================")
        print("🎯 TUYA DEVICE ENCONTRADO")
        print("==============================")


        let virtualID =
            json["gwId"]
            as? String


        let advertisedIP =
            json["ip"]
            as? String


        let productID =
            json["productKey"]
            as? String


        let version =
            json["version"]
            as? String


        let mac =
            json["mac"]
            as? String


        let name =
            json["name"]
            as? String
            ?? "Dispositivo Tuya"


        print(
            "Nome:",
            name
        )


        print(
            "Virtual ID:",
            virtualID ?? "-"
        )


        print(
            "IP:",
            advertisedIP
            ?? remoteIP
            ?? "-"
        )


        print(
            "Product ID:",
            productID ?? "-"
        )


        print(
            "Versão:",
            version ?? "-"
        )


        print(
            "MAC:",
            mac ?? "-"
        )


        print(
            "Porta:",
            port
        )


        print("==============================")


        guard
            let virtualID
        else {

            print(
                "⚠️ Pacote Tuya sem gwId."
            )

            return
        }


        if devices.contains(
            where: {
                $0.virtualID == virtualID
            }
        ) {

            print(
                "ℹ️ Dispositivo já encontrado."
            )

            return
        }


        let device =
            NetworkDevice(
                name: name,
                host: advertisedIP ?? remoteIP ?? "-",
                port: String(port),
                manufacturer: "Tuya",
                isTuya: true,
                virtualID: virtualID,
                productID: productID,
                version: version,
                mac: mac,
                localKey: nil
            )


        devices.append(
            device
        )


        print(
            "✅ Dispositivo adicionado ao scanner"
        )

        print(
            "Nome:",
            device.name
        )

        print(
            "IP:",
            device.host
        )

        print(
            "Virtual ID:",
            virtualID
        )

        print("==============================")
    }


    // MARK: - IP

    private nonisolated static func ipAddress(
        from storage: sockaddr_storage
    ) -> String? {

        var storage =
            storage


        if storage.ss_family ==
            sa_family_t(AF_INET) {

            var address =
                withUnsafePointer(
                    to: &storage
                ) {

                    $0.withMemoryRebound(
                        to: sockaddr_in.self,
                        capacity: 1
                    ) {
                        $0.pointee
                    }
                }


            var buffer =
                [UInt8](
                    repeating: 0,
                    count: Int(
                        INET_ADDRSTRLEN
                    )
                )


            let result =
                inet_ntop(
                    AF_INET,
                    &address.sin_addr,
                    &buffer,
                    socklen_t(
                        INET_ADDRSTRLEN
                    )
                )


            guard result != nil else {
                return nil
            }


            return String(
                decoding:
                    buffer.prefix {
                        $0 != 0
                    },
                as: UTF8.self
            )
        }


        if storage.ss_family ==
            sa_family_t(AF_INET6) {

            var address =
                withUnsafePointer(
                    to: &storage
                ) {

                    $0.withMemoryRebound(
                        to: sockaddr_in6.self,
                        capacity: 1
                    ) {
                        $0.pointee
                    }
                }


            var buffer =
                [UInt8](
                    repeating: 0,
                    count: Int(
                        INET6_ADDRSTRLEN
                    )
                )


            let result =
                inet_ntop(
                    AF_INET6,
                    &address.sin6_addr,
                    &buffer,
                    socklen_t(
                        INET6_ADDRSTRLEN
                    )
                )


            guard result != nil else {
                return nil
            }


            return String(
                decoding:
                    buffer.prefix {
                        $0 != 0
                    },
                as: UTF8.self
            )
        }


        return nil
    }


    // MARK: - Stop

    func stop() {

        scanning = false

        print("🛑 Scanner parado")

        let sources = Array(receiveSources.values)

        receiveSources.removeAll()

        for source in sources {
            source.cancel()
        }

        sockets.removeAll()
    }

    // MARK: - Deinit

    deinit {

        for source in receiveSources.values {

            source.cancel()
        }
    }
}
