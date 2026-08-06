//
//  NovaDigitalService.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import Foundation

final class NovaDigitalService {

    static let shared = NovaDigitalService()

    private init() {}

    func turnOn(device: LocalDevice) {

        print("Ligando \(device.name)")

    }

    func turnOff(device: LocalDevice) {

        print("Desligando \(device.name)")

    }

    func status(device: LocalDevice) {

        print("Consultando estado")

    }

}
