//
//  DeviceSettingsView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//

import SwiftUI


struct DeviceSettingsView: View {


    @Binding var device: Device


    @State private var nome: String = ""
    @State private var ambiente: String = ""



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



            // MARK: - Rede

            Section(
                "Rede"
            ) {


                infoRow(
                    titulo: "IP",
                    valor: device.ip ?? "-"
                )


                infoRow(
                    titulo: "MAC",
                    valor: device.mac ?? "-"
                )


                infoRow(
                    titulo: "Sinal",
                    valor:
                        device.signal != nil
                        ?
                        "\(device.signal!) dBm"
                        :
                        "-"
                )


            }



            // MARK: - Tuya

            Section(
                "NovaDigital / Tuya"
            ) {


                infoRow(
                    titulo: "Product ID",
                    valor:
                        device.productID ?? "-"
                )



                infoRow(
                    titulo: "Virtual ID",
                    valor:
                        device.virtualID ?? "-"
                )



                infoRow(
                    titulo: "Local Key",
                    valor:
                        device.localKey ?? "-"
                )


            }



            // MARK: - Teste

            Section {


                Button {


                    testarConexao()


                } label: {


                    HStack {


                        Image(
                            systemName:
                                "wifi"
                        )


                        Text(
                            "Testar conexão"
                        )


                    }

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


        }

        .onDisappear {


            salvarAlteracoes()

        }


    }



    private func salvarAlteracoes() {


        device.name = nome

        device.room = ambiente


    }



    private func testarConexao() {


        print(
            "Testando conexão com \(device.name)"
        )


        // Futuro:
        // NovaDigitalService.shared.ping(device)

    }




    private func infoRow(

        titulo:String,

        valor:String

    ) -> some View {


        HStack {


            Text(titulo)


            Spacer()


            Text(valor)

                .foregroundStyle(
                    .secondary
                )


        }


    }


}
