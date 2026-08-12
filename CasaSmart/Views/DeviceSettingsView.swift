//
//  DeviceSettingsView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//

import SwiftUI


struct DeviceSettingsView: View {
    
    @EnvironmentObject var store: DeviceStore
    @Environment(\.dismiss) private var dismiss
    @Binding var device: Device
    
    @State private var testandoConexao = false
    @State private var resultadoConexao: String?
    @State private var mostrandoConfirmacaoDeExclusao = false
    @State private var nome: String = ""
    @State private var ambiente: String = ""
    @State private var ip = ""
    @State private var virtualID = ""
    @State private var productID = ""
    @State private var localKey = ""
    
    
    var body: some View {
        
        
        
        
        Form {
            // MARK: - Geral
            
            Section(
                "Dispositivo"
            ) {
                
                
                TextField(
                    "Nome",
                    text: $nome
                )
                
                
                TextField(
                    "Ambiente",
                    text: $ambiente
                )
                
                
            }
            
            Section("Rede") {
                TextField(
                    "IP",
                    text: $ip
                )
                .keyboardType(.numbersAndPunctuation)

                infoRow(
                    titulo: "MAC",
                    valor: device.mac ?? "-"
                )

                infoRow(
                    titulo: "Sinal",
                    valor: device.signal != nil
                    ? "\(device.signal!) dBm"
                    : "-"
                )
            }
            
            // MARK: - Tuya
            
            Section("NovaDigital / Tuya") {
                TextField(
                    "Product ID",
                    text: $productID
                )

                TextField(
                    "Virtual ID",
                    text: $virtualID
                )

                SecureField(
                    "Local Key",
                    text: $localKey
                )
            }
            
            
            // MARK: - Teste
            
            Section("Conexão") {
                Button {
                    testarConexao()
                } label: {
                    HStack {
                        Image(
                            systemName: "wifi"
                        )
                        
                        Text(
                            testandoConexao
                            ? "Testando conexão..."
                            : "Testar conexão"
                        )
                        
                        Spacer()
                        
                        if testandoConexao {
                            ProgressView()
                        }
                    }
                }
                .disabled(testandoConexao || optionalValue(ip) == nil)
                
                if let resultadoConexao {
                    Text(resultadoConexao)
                        .font(.footnote)
                        .foregroundStyle(
                            device.online
                            ? .green
                            : .red
                        )
                }
            }
            
            Section {
                Button(
                    role: .destructive
                ) {
                    mostrandoConfirmacaoDeExclusao = true

                } label: {
                    Label(
                        "Excluir dispositivo",
                        systemImage: "trash"
                    )
                }
            }
            
        }
        
        .navigationTitle(
            "Configurações"
        )
        
        .navigationBarTitleDisplayMode(
            .inline
        )
        
        .onAppear {
            
            
            nome = device.name
            ambiente = device.room
            ip = device.ip ?? ""
            virtualID = device.virtualID ?? ""
            productID = device.productID ?? ""
            localKey = device.localKey ?? ""
            
            
        }
        
        .toolbar {
            
            ToolbarItem(
                placement: .topBarTrailing
            ) {
                
                Button("Salvar") {
                    
                    salvarAlteracoes()
                    
                }
                
            }
            
        }
        .alert(
            "Excluir dispositivo?",
            isPresented: $mostrandoConfirmacaoDeExclusao
        ) {
            Button(
                "Excluir",
                role: .destructive
            ) {
                store.delete(device)
                dismiss()
            }

            Button(
                "Cancelar",
                role: .cancel
            ) {
            }

        } message: {
            Text(
                "Essa ação remove o dispositivo do CasaSmart."
            )
        }
    }
    
    
    
    private func salvarAlteracoes() {
        device.name = nome
        device.room = ambiente
        device.ip = optionalValue(ip)
        device.virtualID = optionalValue(virtualID)
        device.productID = optionalValue(productID)
        device.localKey = optionalValue(localKey)

        store.update(device)
    }
    
    
    private func testarConexao() {
        guard !testandoConexao else {
            return
        }
        
        testandoConexao = true
        resultadoConexao = nil
        
        var deviceToTest = device
        deviceToTest.ip = optionalValue(ip)
        
        Task {
            let connected = await NovaDigitalService.shared.ping(
                device: deviceToTest
            )
            
            testandoConexao = false
            
            device.online = connected
            
            resultadoConexao = connected
            ? "Dispositivo encontrado na rede."
            : "Não foi possível conectar ao dispositivo."
            
            store.update(device)
        }
    }
    
    
    private func optionalValue( _ value: String ) -> String? { let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }
    
    private func infoRow(
        titulo: String,
        valor: String
    ) -> some View {
        HStack {
            Text(titulo)
            
            Spacer()
            
            Text(valor)
                .foregroundStyle(.secondary)
        }
    }
}
