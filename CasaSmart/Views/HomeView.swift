//
//  HomeView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import SwiftUI

struct HomeView: View {

    @StateObject
    private var vm = HomeViewModel()


    private var favoritos: [Device] {

        vm.devices.prefix(2).map { $0 }

    }


    private var ambientes: [String] {

        Array(
            Set(vm.devices.map { $0.room })
        )
        .sorted()

    }

    var body: some View {

        NavigationStack {

            ZStack {

                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color.blue.opacity(0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()


                ScrollView(
                    showsIndicators: false
                ) {


                    VStack(
                        alignment: .leading,
                        spacing: 28
                    ) {


                        // MARK: - Cabeçalho

                        header



                        // MARK: - Status

                        statusCard



                        // MARK: - Favoritos

                        sectionTitle(
                            "Favoritos ⭐"
                        )


                        ScrollView(
                            .horizontal,
                            showsIndicators: false
                        ) {

                            HStack(
                                spacing: 16
                            ) {

                                ForEach(
                                    vm.devices.indices.prefix(2),
                                    id: \.self
                                ) { index in

                                    DeviceCard(
                                        device: $vm.devices[index]
                                    )

                                    .frame(
                                        width: 260
                                    )

                                }

                            }

                        }



                        // MARK: - Ambientes


                        sectionTitle(
                            "Ambientes"
                        )


                        ForEach(
                            ambientes,
                            id: \.self
                        ) { ambiente in


                            roomSection(
                                ambiente
                            )

                        }


                    }
                    .padding()

                }

            }

            .navigationBarHidden(true)

        }

    }



    // MARK: - Header


    private var header: some View {


        VStack(
            alignment: .leading,
            spacing: 8
        ) {


            HStack {


                VStack(
                    alignment: .leading
                ) {


                    Text(
                        "Casa Smart"
                    )
                    .font(
                        .largeTitle.bold()
                    )


                    Text(
                        greeting
                    )
                    .foregroundStyle(
                        .secondary
                    )

                }


                Spacer()



                Image(
                    systemName: "house.fill"
                )
                .font(
                    .title
                )
                .padding(14)
                .background(
                    .ultraThinMaterial
                )
                .clipShape(
                    Circle()
                )

            }

        }

    }



    // MARK: - Status


    private var statusCard: some View {


        HStack {


            VStack(
                alignment: .leading,
                spacing: 6
            ) {


                Text(
                    "Sua casa está"
                )


                Text(
                    "Online"
                )
                .font(
                    .title2.bold()
                )
                .foregroundStyle(
                    .green
                )

            }


            Spacer()



            VStack(
                alignment: .trailing
            ) {


                Text(
                    "\(vm.devices.count)"
                )
                .font(
                    .title.bold()
                )


                Text(
                    "Dispositivos"
                )
                .foregroundStyle(
                    .secondary
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




    // MARK: - Sala


    private func roomSection(
        _ room: String
    ) -> some View {


        VStack(
            alignment: .leading,
            spacing: 14
        ) {


            Text(
                room
            )
            .font(
                .title3.bold()
            )



            LazyVGrid(

                columns: [

                    GridItem(.flexible()),
                    GridItem(.flexible())

                ],

                spacing: 16

            ) {


                ForEach(
                    vm.devices.indices,
                    id: \.self
                ) { index in


                    if vm.devices[index].room == room {


                        DeviceCard(
                            device: $vm.devices[index]
                        )


                    }

                }

            }


        }

    }




    private func sectionTitle(
        _ title: String
    ) -> some View {


        Text(title)
            .font(
                .title2.bold()
            )

    }



    private var greeting: String {


        let hour = Calendar.current.component(
            .hour,
            from: Date()
        )


        if hour < 12 {

            return "Bom dia 👋"

        } else if hour < 18 {

            return "Boa tarde 👋"

        } else {

            return "Boa noite 👋"

        }

    }

}
