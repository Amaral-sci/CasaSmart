//
//  DeviceCard.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import SwiftUI
import SwiftData

struct DeviceCard: View {

    @Binding var device: Device

    @EnvironmentObject
    var store: DeviceStore
    
    private var comandoEmAndamento: Bool {store.isCommandPending(device)
    }
    
    var body: some View {

        NavigationLink {

            DeviceDetailView(device: $device
            )
            .environmentObject(store)
            
        } label: {


            VStack(alignment: .leading, spacing: 18) {


                HStack {

                    Image(systemName: device.icon)
                        .font(.system(size: 28))
                        .foregroundStyle(
                            device.isOn ? .yellow : .gray
                        )
                        .padding(12)
                        .background(
                            device.isOn
                            ? Color.yellow.opacity(0.25) : Color.gray.opacity(0.15)
                        )
                        .clipShape(Circle())


                    Spacer()


                    Circle()
                        .fill(device.online ? .green : .red)
                        .frame(width: 12)
                }
                Spacer()

                Text(device.name).font(.title3.bold())
                Text(device.room).foregroundStyle(.secondary)
                
                if let signal = device.signal {

                    Label("\(signal)dBm", systemImage: "wifi")
                    .font(.caption)
                }

                HStack {

                    Spacer()

                    Button {
                        store.toggle(device)

                    } label: {
                        HStack {
                            if comandoEmAndamento {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(
                                    systemName: device.isOn ? "power.circle.fill" : "power.circle" )
                            }

                            Text( comandoEmAndamento ? "Enviando..." : ( device.isOn ? "Ligado" : "Desligado" ))
                        }
                        .font(.headline)
                        .foregroundStyle(device.isOn ? .yellow : .secondary)
                    }
                    .buttonStyle(.borderless)
                    .disabled(comandoEmAndamento)
                    .tint(.yellow)
                }
            }
            .padding()
            .frame(height: 260)
            .background(device.isOn ? Color.yellow.opacity(0.18) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 28))

        }
        // impede o NavigationLink de ficar azul
        .buttonStyle(.plain)

    }
}

#Preview {

    let container = try! ModelContainer(for: DeviceEntity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))


    let store = DeviceStore(context:container.mainContext)
    DeviceCard(device:.constant(
                Device(
                    id: UUID(),
                    name: "Teste",
                    room: "Sala",
                    icon: "lightbulb.fill",
                    virtualID: nil,
                    productID: nil,
                    localKey: nil,
                    ip: nil,
                    mac: nil,
                    online: true,
                    signal: -40,
                    isOn: true
                )))
    .environmentObject(store)

}
