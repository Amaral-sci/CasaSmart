//
//  DeviceDetector.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//

import Foundation
import Network

final class DeviceDetector {


    static let shared = DeviceDetector()



    private init() {}



    func analyze(
        ip: String
    ) async -> NetworkDevice {


        var device = NetworkDevice(

            name: "Dispositivo encontrado",

            host: ip,

            port: ""

        )


        let tuya =
        await checkPort(
            ip: ip,
            port: 6668
        )


        if tuya {

            device.isTuya = true

            device.manufacturer = "Tuya / NovaDigital"

        }



        return device

    }





    private func checkPort(
        ip:String,
        port:Int
    ) async -> Bool {


        return await withCheckedContinuation { continuation in


            let socket = NWConnection(

                host: NWEndpoint.Host(ip),

                port: NWEndpoint.Port(
                    "\(port)"
                )!,

                using: .tcp

            )



            socket.stateUpdateHandler = { state in


                switch state {


                case .ready:

                    continuation.resume(
                        returning: true
                    )


                    socket.cancel()



                case .failed(_),
                     .cancelled:


                    continuation.resume(
                        returning: false
                    )


                    socket.cancel()



                default:
                    break

                }


            }



            socket.start(
                queue: .global()
            )


        }


    }

}
