//
//  DeviceCard.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import SwiftUI
import SwiftData

struct DeviceCard: View {

    @State private var pulse = false
    
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
                    .foregroundStyle(device.isOn ? .yellow : .gray)
                    .padding(12)
                    .background(device.isOn ?Color.yellow.opacity(0.25) : Color.gray.opacity(0.15))
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
                        
                        Task {
                            await store.toggleCloud(device)
                        }
                        
                    } label: {
                        
                        HStack(spacing: 8) {
                            
                            if comandoEmAndamento {
                                
                                ProgressView()
                                   // .controlSize(.small)
                                //aqui em baixo
                                    .scaleEffect(1.2)
                            } else {
                                
                                Image(
                                    systemName: device.isOn
                                    ? "power.circle.fill"
                                    : "power.circle"
                                )
                                .font(.system(size: 18, weight: .medium))
                                
                            }
                            
                            Text(
                                comandoEmAndamento
                                ? "Enviando..."
                                : device.isOn
                                ? "Ligado"
                                : "Desligado"
                            )
                            .font(.subheadline.weight(.medium))
                        }
                        .foregroundStyle(
                            device.isOn
                            ? .white
                            : .primary
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            device.isOn
                            ? Color.yellow
                            : Color(.systemGray5)
                        )
                        .clipShape(
                            Capsule()
                        )
                        
                    }
                    .animation(.spring(),value: comandoEmAndamento)
                    .buttonStyle(.plain)
                    .disabled(comandoEmAndamento)
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
            virtualID: "ebfc259a65e8950567imiu",
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
