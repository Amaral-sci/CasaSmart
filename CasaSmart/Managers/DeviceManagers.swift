//
//  DeviceManagers.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import Foundation
internal import Combine

@MainActor
final class DeviceManager: ObservableObject {

    @Published private(set) var devices: [Device] = []

    func add(_ device: Device) {
        devices.append(device)
    }

    func update(_ device: Device) {

    }

    func remove(_ device: Device) {

    }

}
