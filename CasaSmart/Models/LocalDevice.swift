//
//  LocalDevice.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import Foundation

struct LocalDevice: Identifiable {

    let id = UUID()

    let ip: String
    let mac: String
    let name: String
}
