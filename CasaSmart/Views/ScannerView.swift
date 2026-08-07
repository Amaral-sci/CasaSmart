//
//  ScannerView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//

import SwiftUI
import SwiftData


struct ScannerView: View {


@StateObject
    private var scanner = NetworkScanner()

@EnvironmentObject
    var homeVM: HomeViewModel

@Environment(\.modelContext)
    private var context
    
    var body: some View {


        NavigationStack {


            VStack {


                if scanner.scanning {


                    ProgressView(
                        "Procurando dispositivos..."
                    )


                }


                List(
                    scanner.devices
                ) { device in


                    VStack(
                        alignment: .leading,
                        spacing: 12
                    ) {


                        HStack {


                            VStack(
                                alignment: .leading
                            ) {


                                Text(device.name)
                                    .font(.headline)


                                Text(device.host)
                                    .foregroundStyle(.secondary)


                                Text(device.port)
                                    .font(.caption)



                            }


                            Spacer()



                            Button {


                                adicionar(device)



                            } label: {


                                Text("Adicionar")

                            }
                            .buttonStyle(.borderedProminent)


                        }


                    }


                }


            }

            .navigationTitle(
                "Scanner Rede"
            )

            .toolbar {


                Button {


                    scanner.scan()


                } label: {


                    Image(
                        systemName:
                        "wifi"
                    )


                }


            }


        }

    }
    private func adicionar(
        _ networkDevice: NetworkDevice
    ) {


        let novoDevice = Device(

            id: UUID(),

            name:
                networkDevice.name,
            
            room:
                "Sem ambiente",

            icon:
                "lightbulb.fill",


            virtualID: nil,

            productID: nil,

            localKey: nil,


            ip:
                networkDevice.host,


            mac:
                nil,


            online:
                true,


            signal: nil,


            isOn: false

        )


        homeVM.add(novoDevice)

        let store = DeviceStore(context: context)

        store.add(novoDevice)
    }
}
