//
//  NetworkDevice.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//
//
import Foundation


struct NetworkDevice: Identifiable, Codable {

    var id = UUID()

    var name: String

    var host: String

    var port: String


    var manufacturer: String

    var isTuya: Bool


    var virtualID: String?

    var productID: String?

    var version: String?

    var mac: String?


    // NOVO
    var localKey: String?


    // Estado

    var isOn: Bool = false

}
