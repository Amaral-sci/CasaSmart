//
//  NetworkScanner.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//
import Foundation
import Network
import Combine


@MainActor
final class NetworkScanner: ObservableObject {


    @Published
    var devices: [NetworkDevice] = []


    @Published
    var scanning = false



    private var browser: NWBrowser?



    func scan() {


        devices.removeAll()

        scanning = true



        let descriptor =
        NWBrowser.Descriptor.bonjour(
            type: "_http._tcp",
            domain: nil
        )


        let parameters =
        NWParameters.tcp



        browser =
        NWBrowser(
            for: descriptor,
            using: parameters
        )



        browser?.browseResultsChangedHandler = {
            [weak self] results, changes in


            Task { @MainActor in


                guard let self else {
                    return
                }


                for result in results {


                    switch result.endpoint {


                    case .service(
                        let name,
                        let type,
                        let domain,
                        _
                    ):


                        let device =
                        NetworkDevice(
                            name: name,
                            host: domain,
                            port: type
                        )


                        if !self.devices.contains(
                            where: { $0.name == device.name }
                        ) {

                            self.devices.append(device)

                        }


                    default:
                        break
                    }

                }


            }

        }


        browser?.stateUpdateHandler = { [weak self] state in


            Task { @MainActor in


                guard let self else {
                    return
                }


                switch state {


                case .ready:

                    self.scanning = false



                case .failed(_):

                    self.scanning = false



                default:

                    break

                }


            }


        }



        browser?.start(
            queue: .main
        )


    }





    func stop() {


        browser?.cancel()

        scanning = false

    }


}
