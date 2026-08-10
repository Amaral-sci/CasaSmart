//
//  ScannerView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//

import SwiftUI

struct ScannerView: View {

    @StateObject
    private var scanner = NetworkScanner()
    
    @State
    private var showingDeviceSetup = false

    @EnvironmentObject
    private var store: DeviceStore

    var body: some View {
        NavigationStack {
            VStack {
                if scanner.scanning {
                    ProgressView(
                        "Procurando dispositivos..."
                    )
                }

                List(scanner.devices) { device in
                    HStack {
                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text(device.name)
                                .font(.headline)

                            Text(device.host)
                                .foregroundStyle(.secondary)

                            Text(device.port)
                                .font(.caption)
                        }

                        Spacer()

                        Button("Adicionar") {
                            adicionar(device)
                        }
                        .buttonStyle(.borderedProminent)
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
                DeviceSetupView()
                    .environmentObject(store)
            }
        }
    }

    private func adicionar(
        _ networkDevice: NetworkDevice
    ) {
        let novoDevice = Device(
            id: UUID(),
            name: networkDevice.name,
            room: "Sem ambiente",
            icon: "lightbulb.fill",
            virtualID: nil,
            productID: nil,
            localKey: nil,
            ip: networkDevice.host,
            mac: nil,
            online: true,
            signal: nil,
            isOn: false
        )

        store.add(novoDevice)
    }
}
