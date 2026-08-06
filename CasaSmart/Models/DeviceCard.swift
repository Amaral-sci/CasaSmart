//
//  DeviceCard.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import SwiftUI

struct DeviceCard: View {

    @Binding var device: Device

    var body: some View {

        NavigationLink {

            DeviceDetailView(
                device: $device
            )

        } label: {


            VStack(
                alignment: .leading,
                spacing: 18
            ) {


                // MARK: - Topo

                HStack {


                    Image(systemName: device.icon)
                        .font(
                            .system(size: 28)
                        )
                        .foregroundStyle(
                            device.isOn ?
                            .yellow :
                            .gray
                        )
                        .frame(
                            width: 55,
                            height: 55
                        )
                        .background(
                            device.isOn ?
                            Color.yellow.opacity(0.25) :
                            Color.gray.opacity(0.15)
                        )
                        .clipShape(
                            Circle()
                        )


                    Spacer()



                    Circle()
                        .fill(
                            device.online ?
                            .green :
                            .red
                        )
                        .frame(
                            width: 12
                        )

                }



                Spacer()



                // MARK: - Informações

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {


                    Text(device.name)
                        .font(
                            .title3.bold()
                        )
                        .lineLimit(1)


                    Text(device.room)
                        .foregroundStyle(
                            .secondary
                        )



                    if let signal = device.signal {


                        Label(
                            "\(signal)dBm",
                            systemImage: "wifi"
                        )
                        .font(
                            .caption
                        )
                        .foregroundStyle(
                            .secondary
                        )

                    }


                }



                // MARK: - Switch visual


                HStack {


                    Spacer()


                    RoundedRectangle(
                        cornerRadius: 20
                    )
                    .fill(
                        device.isOn ?
                        Color.yellow :
                        Color.gray.opacity(0.4)
                    )
                    .frame(
                        width: 55,
                        height: 30
                    )
                    .overlay {


                        Circle()
                            .fill(.white)
                            .frame(
                                width: 26
                            )
                            .offset(
                                x: device.isOn ? 12 : -12
                            )


                    }


                }


            }
            .padding()
            .frame(
                height: 210
            )
            .background {


                device.isOn ?
                Color.yellow.opacity(0.15) :
                Color(.systemGray6)


            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 28
                )
            )

        }
        .buttonStyle(.plain)

    }

}
