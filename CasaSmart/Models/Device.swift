//
//  Device.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import Foundation

struct Device: Identifiable, Hashable {

    let id: UUID

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
}
