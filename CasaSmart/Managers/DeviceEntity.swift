//
//  DeviceEntity.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//

import Foundation
import SwiftData


@Model
final class DeviceEntity {


    var id: UUID

    var name: String

    var room: String

    var icon: String


    // Tuya

    var virtualID: String?

    var productID: String?

    var localKey: String?


    // Rede

    var ip: String?

    var mac: String?

    var online: Bool

    var signal: Int?


    // Estado

    var isOn: Bool



    init(
        device: Device
    ) {


        self.id = device.id

        self.name = device.name

        self.room = device.room

        self.icon = device.icon


        self.virtualID = device.virtualID

        self.productID = device.productID

        self.localKey = device.localKey


        self.ip = device.ip

        self.mac = device.mac

        self.online = device.online

        self.signal = device.signal


        self.isOn = device.isOn

    }



    func toDevice() -> Device {


        Device(

            id: id,

            name: name,

            room: room,

            icon: icon,

            virtualID: virtualID,

            productID: productID,

            localKey: localKey,

            ip: ip,

            mac: mac,

            online: online,

            signal: signal,

            isOn: isOn

        )

    }


}
