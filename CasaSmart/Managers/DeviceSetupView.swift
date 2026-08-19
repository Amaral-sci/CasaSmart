//
//  DeviceSetupView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 10/08/26.
//

import SwiftUI
import Network

struct DeviceSetupView: View {

    let networkDevice: NetworkDevice?
    
    @EnvironmentObject
    private var store: DeviceStore

    @Environment(\.dismiss)
    private var dismiss
    
    
    @State private var name = ""
    @State private var room = ""
    @State private var ip = ""
    @State private var virtualID = ""
    @State private var productID = ""
    @State private var localKey = ""
    @State private var errorMessage: String?

    private var cleanedIP: String {
        ip.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private var canSave: Bool {
        !name.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        .isEmpty
        &&
        IPv4Address(cleanedIP) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dispositivo") {
                    TextField(
                        "Nome",
                        text: $name
                    )

                    TextField(
                        "Ambiente",
                        text: $room
                    )
                }

                Section("Rede local") {
                    TextField(
                        "IP do dispositivo",
                        text: $ip
                    )
                    .keyboardType(.numbersAndPunctuation)

                    Text(
                        "Exemplo: 192.168.1.50"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                Section("NovaDigital / Tuya") {
                    TextField(
                        "Virtual ID",
                        text: $virtualID
                    )

                    TextField(
                        "Product ID",
                        text: $productID
                    )

                    SecureField(
                        "Local Key",
                        text: $localKey
                    )
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Adicionar dispositivo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .cancellationAction
                ) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {
                    Button("Adicionar") {
                        saveDevice()
                    }
                    .disabled(!canSave)
                }
            }
            .task {

                guard let networkDevice else {
                    return
                }

                name =
                networkDevice.name

                ip =
                networkDevice.host

                virtualID =
                networkDevice.virtualID ?? ""

                productID =
                networkDevice.productID ?? ""

            }
        }
    }

    private func saveDevice() {
        guard canSave else {
            return
        }

        guard !store.devices.contains(where: {
            $0.ip == cleanedIP
        }) else {
            errorMessage =
                "Já existe um dispositivo com este IP."
            return
        }

        let device = Device(
            id: UUID(),
            name: cleaned(name),
            room: cleaned(room).isEmpty
            ? "Sem ambiente"
            : cleaned(room),
            icon: "lightbulb.fill",
            virtualID: optionalValue(virtualID),
            productID: optionalValue(productID),
            localKey: optionalValue(localKey),
            ip: cleanedIP,
            mac: nil,
            online: true,
            signal: nil,
            isOn: false
        )

        store.add(device)

        dismiss()
    }

    private func cleaned(
        _ value: String
    ) -> String {
        value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }

    private func optionalValue(
        _ value: String
    ) -> String? {
        let value = cleaned(value)

        return value.isEmpty
        ? nil
        : value
    }
}
