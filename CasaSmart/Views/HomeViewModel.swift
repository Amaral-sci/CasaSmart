//
//  HomeViewModel.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import Foundation
internal import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var devices: [Device] = [

        Device(
            id: UUID(),
            name: "Iluminação Entrada",
            room: "Sala",
            icon: "lightbulb.fill",
            virtualID: nil,
            productID: nil,
            localKey: nil,
            ip: nil,
            mac: nil,
            online: true,
            signal: -48,
            isOn: true
        ),

        Device(
            id: UUID(),
            name: "Luz Cozinha",
            room: "Cozinha",
            icon: "lightbulb.fill",
            virtualID: nil,
            productID: nil,
            localKey: nil,
            ip: nil,
            mac: nil,
            online: true,
            signal: -52,
            isOn: false
        ),

        Device(
            id: UUID(),
            name: "Luz Corredor",
            room: "Corredor",
            icon: "lightbulb.fill",
            virtualID: nil,
            productID: nil,
            localKey: nil,
            ip: nil,
            mac: nil,
            online: true,
            signal: -45,
            isOn: true
        )
    ]


    func toggle(_ device: Device) {

        guard let index = devices.firstIndex(of: device) else {
            return
        }

        devices[index].isOn.toggle()

    }

}
