//
//  TuyaTCPClient.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 12/08/26.
//
//
import Foundation
import Network


final class TuyaTCPClient {
    
    
    static let shared = TuyaTCPClient()
    
    
    private init(){}
    
    
    
    private let port: UInt16 = 6668
    
    
    
    // MARK: - Connect
    
    
    func connect(
        ip: String
    ) async throws -> NWConnection {
        
        
        guard let port = NWEndpoint.Port(
            rawValue: port
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
                        
                        await state.success()
                    }
                    
                    
                    
                case .failed(let error):
                    
                    
                    Task {
                        
                        await state.failure(
                            error
                        )
                    }
                    
                    
                    
                case .cancelled:
                    
                    
                    Task {
                        
                        await state.failure(
                            NovaDigitalError.conexaoFalhou
                        )
                    }
                    
                    
                    
                default:
                    
                    break
                }
            }
            
            
            
            connection.start(
                queue:
                        .global(
                            qos: .userInitiated
                        )
            )
        }
    }
    
    
    
    
    
    
    // MARK: - Send
    
    
    func send(
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
                completion:
                        .contentProcessed {
                            
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
    
    
    
    
    
    
    
    // MARK: - Receive
    
    
    func receive(
        connection: NWConnection,
        timeout: TimeInterval = 5
    ) async throws -> Data {
        
        
        return try await withThrowingTaskGroup(
            of: Data.self
        ) { group in
            
            
            group.addTask {
                
                let buffer = DataBuffer()
                
                while true {
                    
                    
                    let chunk =
                    try await withCheckedThrowingContinuation {
                        
                        (
                            continuation:
                                CheckedContinuation<Data, Error>
                        ) in
                        
                        
                        connection.receive(
                            minimumIncompleteLength: 1,
                            maximumLength: 65535
                        ) {
                            
                            data,
                            _,
                            complete,
                            error in
                            
                            print("====== TCP RECEIVE CALLBACK ======")
                            print("DATA:", data?.count ?? 0)
                            print("COMPLETE:", complete)
                            print("ERROR:", error?.localizedDescription ?? "nil")
                            
                            if let error {
                                
                                continuation.resume(
                                    throwing:error
                                )
                                
                                return
                            }
                            
                            
                            if let data,
                               !data.isEmpty {
                                
                                
                                continuation.resume(
                                    returning:data
                                )
                                
                                return
                            }
                            
                            
                            if complete {

                                Task {

                                    if await buffer.count() > 0 {

                                        continuation.resume(
                                            returning: await buffer.value()
                                        )

                                    } else {

                                        continuation.resume(
                                            throwing:
                                            NovaDigitalError.conexaoFalhou
                                        )
                                    }
                                }

                                return
                            }
                        }
                    }
                    
                    
                    await buffer.append(chunk)
                    
                    print("TCP recebeu:", chunk.count,"bytes")
                    
                    
                    //
                    // Tuya Frame mínimo:
                    // header 16
                    // payload
                    // hmac 32
                    // footer 4
                    //
                    
                    let currentBuffer = await buffer.value()


                    if currentBuffer.count >= 52 {

                        let length =
                        TuyaFrame.readUInt32BE(
                            currentBuffer,
                            offset: 12
                        )


                        let total =
                        16 + Int(length)


                        if currentBuffer.count >= total {

                            return currentBuffer
                        }
                    }
                }
            }
            
            
            
            group.addTask {
                
                try await Task.sleep(
                    for:
                            .seconds(timeout)
                )
                
                
                throw NovaDigitalError.timeout
            }
            
            
            
            let result =
            try await group.next()!
            
            
            group.cancelAll()
            
            
            return result
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
        
        
        
        
        
        func success(){
            
            
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
        
        
        
        
        
        
        func failure(
            _ error: Error
        ){
            
            
            guard !finished,
                  let continuation else {
                
                return
            }
            
            
            finished = true
            
            self.continuation = nil
            
            
            continuation.resume(
                throwing:error
            )
        }
    }
}


// MARK: - Data Buffer Swift 6

private actor DataBuffer {

    private var data = Data()


    func append(
        _ newData: Data
    ) {

        data.append(newData)
    }


    func value() -> Data {

        data
    }


    func count() -> Int {

        data.count
    }
}
