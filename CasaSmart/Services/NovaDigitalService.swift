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



    // MARK: - Ligar / Desligar


    func toggle(
        device: Device
    ) async throws {


        print(
            "Enviando comando para:",
            device.name
        )


        /*
         Futuramente:

         1 - Usar IP do dispositivo
         2 - Enviar comando Tuya
         3 - Receber resposta
        */


    }




    func turnOn(
        device: Device
    ) async throws {


        print(
            "Ligando \(device.name)"
        )


    }




    func turnOff(
        device: Device
    ) async throws {


        print(
            "Desligando \(device.name)"
        )


    }




    // MARK: - Teste de conexão


    func ping(
        device: Device
    ) async -> Bool {


        guard let ip = device.ip else {

            return false

        }


        print(
            "Testando IP:",
            ip
        )


        return true

    }


}
