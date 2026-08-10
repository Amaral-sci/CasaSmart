//
//  DeviceDetailView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import SwiftUI


struct DeviceDetailView: View {

    @Binding var device: Device

    @EnvironmentObject var store: DeviceStore
    
    private var comandoEmAndamento: Bool {store.isCommandPending(device)}
    
    private var mostrarErroDeComando: Binding<Bool> { Binding( get: {store.lastCommandError != nil
            }, set: { mostrando in if !mostrando {store.lastCommandError = nil
                }
            })
    }
    
    var body: some View {
        
        
        ZStack {
            
            
            LinearGradient(
                colors: [
                    
                    Color(.systemBackground),
                    
                    device.isOn
                    ? Color.yellow.opacity(0.15)
                    : Color.blue.opacity(0.08)
                    
                ],
                
                startPoint: .top,
                
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            
            
            ScrollView {
                
                
                VStack(
                    spacing: 30
                ) {
                    
                    
                    header
                    
                    
                    
                    powerButton
                    
                    
                    
                    statusCard
                    
                    
                    
                    technicalCard
                    
                    NavigationLink {
                        DeviceSettingsView(
                            device: $device
                        )
                        .environmentObject(store)

                    } label: {
                        HStack {
                            Image(systemName: "gear")
                            Text("Configurações")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    
                }
                .padding()
                
            }
            
            
        }
        
        .navigationTitle(
            "Controle"
        )
        
        .navigationBarTitleDisplayMode(.inline)
        .alert( "Não foi possível enviar o comando", isPresented: mostrarErroDeComando ){
            Button( "OK", role: .cancel) {
                store.lastCommandError = nil
            }

        } message: {
            Text(
                store.lastCommandError
                ?? "Ocorreu um erro inesperado."
            )
        }
        
        
    }
    
    
    
    // MARK: - Cabeçalho
    
    
    private var header: some View {
        
        
        VStack(spacing: 15) {
            
            ZStack {
                
                Circle()
                 .fill(device.isOn ? Color.yellow.opacity(0.25) : Color.gray.opacity(0.15))
                .frame(width: 160, height: 160)
                
                Image(systemName: device.icon)
                    .font(.system(size: 75))
                    .foregroundStyle(device.isOn ? .yellow : .gray)
             }
            
            Text(device.name)
                .font(.largeTitle.bold())
            
            Text(device.room)
            
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
    // MARK: - Botão Energia
    
    private var powerButton: some View {
        
        VStack(spacing: 15) {
            Button {
                withAnimation(.spring) {store.toggle(device)
                    }
            } label: {
                ZStack {
                    Circle()
                        .fill(device.isOn ? Color.yellow : Color(.systemGray5))
                        .frame( width: 110,height: 110 )
                    
                    Image(systemName: "power")
                    .font(.system(size: 45))
                    .foregroundStyle(device.isOn ? .black : .gray )
                }
                
            }
            .buttonStyle(.plain)
            .disabled(comandoEmAndamento)
           
            Text(comandoEmAndamento ? "Enviando comando..." : (device.isOn ? "Ligado" : "Desligado"))
       }
    }
    // MARK: - Status
    
    
    private var statusCard: some View {
        
        
        VStack(spacing: 15) {
            
            detailRow(
                
                icon: "wifi",
                
                title: "Conexão",
                
                value:
                    device.online
                ?
                "Online"
                :
                    "Offline"
                
            )
            
            
            
            if let signal = device.signal {
                
                
                detailRow(
                    
                    icon: "antenna.radiowaves.left.and.right",
                    
                    title: "Sinal",
                    
                    value: "\(signal)dBm"
                    
                )
                
            }
            
            
        }
        
        .padding()
        
        .background(
            .ultraThinMaterial
        )
        
        .clipShape(
            RoundedRectangle(
                cornerRadius: 25
            )
        )
        
        
    }
    
    
    
    // MARK: - Informações Técnicas
    
    
    private var technicalCard: some View {
        
        
        VStack(
            alignment: .leading,
            spacing: 15
        ) {
            
            
            Text(
                "Informações do dispositivo"
            )
            
            .font(
                .headline
            )
            
            
            
            detailRow(
                
                icon:"number",
                
                title:"ID Virtual",
                
                value:
                    device.virtualID ?? "-"
                
            )
            
            
            
            detailRow(
                
                icon:"network",
                
                title:"IP",
                
                value:
                    device.ip ?? "-"
                
            )
            
            
            
            detailRow(
                
                icon:"antenna.radiowaves.left.and.right",
                
                title:"MAC",
                
                value:
                    device.mac ?? "-"
                
            )
            
            
        }
        
        .padding()
        
        .background(
            .ultraThinMaterial
        )
        
        .clipShape(
            RoundedRectangle(
                cornerRadius: 25
            )
        )
        
        
    }
    
    
    
    private func detailRow(
        
        icon:String,
        
        title:String,
        
        value:String
        
    ) -> some View {
        
        
        HStack {
            
            
            Image(systemName: icon)
            
                .frame(
                    width:30
                )
            
            
            
            Text(title)
            
            
            
            Spacer()
            
            
            
            Text(value)
            
                .foregroundStyle(
                    .secondary
                )
            
            
        }
        
    }
    
}

