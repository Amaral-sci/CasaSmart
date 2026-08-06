//
//  DeviceDetailView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import SwiftUI

struct DeviceDetailView: View {

    @Binding var device: Device

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    device.isOn ?
                    Color.yellow.opacity(0.15) :
                    Color.gray.opacity(0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()


            VStack(spacing: 30) {


                // MARK: - Ícone

                ZStack {

                    Circle()
                        .fill(
                            device.isOn ?
                            Color.yellow.opacity(0.25) :
                            Color.gray.opacity(0.15)
                        )
                        .frame(
                            width: 150,
                            height: 150
                        )


                    Image(systemName: device.icon)
                        .font(
                            .system(size: 65)
                        )
                        .foregroundStyle(
                            device.isOn ?
                            .yellow :
                            .gray
                        )
                        .shadow(
                            color: device.isOn ? .yellow : .clear,
                            radius: 20
                        )

                }



                // MARK: - Nome


                VStack(spacing: 8) {

                    Text(device.name)
                        .font(
                            .largeTitle.bold()
                        )


                    Text(device.room)
                        .font(
                            .title3
                        )
                        .foregroundStyle(
                            .secondary
                        )

                }



                // MARK: - Botão principal


                Button {


                    device.isOn.toggle()


                } label: {


                    HStack {


                        Image(
                            systemName:
                                device.isOn ?
                                "power" :
                                "power"
                        )


                        Text(
                            device.isOn ?
                            "Ligado" :
                            "Desligado"
                        )
                        .font(
                            .title3.bold()
                        )


                    }
                    .frame(
                        maxWidth: .infinity
                    )
                    .padding()
                    .background(
                        device.isOn ?
                        Color.yellow :
                        Color.gray.opacity(0.3)
                    )
                    .foregroundStyle(
                        device.isOn ?
                        .black :
                        .primary
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 20
                        )
                    )

                }



                // MARK: - Informações


                VStack(spacing: 15) {


                    infoRow(
                        icon: "wifi",
                        title: "Conexão",
                        value: device.online ?
                        "Online" :
                        "Offline"
                    )


                    if let signal = device.signal {


                        infoRow(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Sinal",
                            value: "\(signal)dBm"
                        )

                    }



                    if let id = device.virtualID {


                        infoRow(
                            icon: "number",
                            title: "ID Tuya",
                            value: id
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


                Spacer()

            }
            .padding()

        }
        .navigationTitle(
            "Dispositivo"
        )
        .navigationBarTitleDisplayMode(
            .inline
        )

    }



    private func infoRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {


        HStack {


            Image(systemName: icon)
                .frame(width: 30)


            Text(title)


            Spacer()


            Text(value)
                .foregroundStyle(
                    .secondary
                )

        }

    }

}
