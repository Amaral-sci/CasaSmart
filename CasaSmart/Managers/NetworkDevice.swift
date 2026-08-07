//
//  NetworkDevice.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//

import Foundation


struct NetworkDevice: Identifiable {


    let id = UUID()


    var name: String

    var host: String

    var port: String


    // Informações extras

    var manufacturer: String?

    var isTuya: Bool = false


}
