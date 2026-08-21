//
//  ScannerView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//
import SwiftUI

struct ScannerView: View {

    @StateObject private var scanner = NetworkScanner()

    @State private var selectedNetworkDevice: NetworkDevice?

    @State private var showingDeviceSetup = false

    @EnvironmentObject private var store: DeviceStore


    var body: some View {

        NavigationStack {

            VStack {

                if scanner.scanning {

                    ProgressView(
                        "Procurando dispositivos..."
                    )
                }


                List {

                    ForEach(scanner.devices) { device in

                        Button {

                            selectedNetworkDevice = device
                            showingDeviceSetup = true

                        } label: {

                            VStack(alignment: .leading, spacing: 5) {

                                Text(device.host)
                                    .font(.headline)

                                Text(device.productID ?? "-")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            .navigationTitle("Scanner Rede")

            .toolbar {

                ToolbarItem(
                    placement: .topBarLeading
                ) {

                    Button {

                        showingDeviceSetup = true

                    } label: {

                        Image(systemName: "plus")
                    }
                }


                ToolbarItem(
                    placement: .topBarTrailing
                ) {

                    Button {

                        scanner.scan()

                    } label: {

                        Image(systemName: "wifi")
                    }
                }
            }


            .sheet(
                isPresented: $showingDeviceSetup
            ) {

                DeviceSetupView(
                    networkDevice: selectedNetworkDevice
                )
                .environmentObject(store)
            }
        }
    }



    private func convertToDevice(
        _ network: NetworkDevice
    ) -> Device {


        Device(

            id: UUID(),

            name: network.name,

            room: "Novo ambiente",

            icon: "lightbulb.fill",

            virtualID: network.virtualID,

            version: network.version,

            productID: network.productID,

            localKey: nil,

            ip: network.host,

            mac: network.mac,

            online: true,

            signal: nil,

            isOn: false
        )
    }



    private func adicionar(
        _ networkDevice: NetworkDevice
    ) {


        let novoDevice = Device(

            id: UUID(),

            name: networkDevice.name,

            room: "Sem ambiente",

            icon: "lightbulb.fill",

            virtualID: networkDevice.virtualID,

            version: networkDevice.version,

            productID: networkDevice.productID,

            localKey: networkDevice.localKey,
            
            ip: networkDevice.host,

            mac: networkDevice.mac,

            online: true,

            signal: nil,

            isOn: false
        )

        print("==============================")
        print("SALVANDO DEVICE")
        print("Nome:", networkDevice.name)
        print("HOST:", networkDevice.host)
        print("VirtualID:", networkDevice.virtualID ?? "nil")
        print("ProductID:", networkDevice.productID ?? "nil")
        print("LocalKey:", networkDevice.localKey ?? "nil")
        print("==============================")
        
        store.add(novoDevice)
    }
}
