//
//  DeviceStore.swift.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//

import Foundation
import SwiftData
import Combine


@MainActor
final class DeviceStore: ObservableObject {
    


    private var context: ModelContext



    @Published var devices: [Device] = []

    @Published var pendingDeviceIDs: Set<UUID> = []

    @Published var lastCommandError: String?

    init(
        context: ModelContext
    ) {

        self.context = context

        load()

    }

    func isCommandPending(
        _ device: Device
    ) -> Bool {
        pendingDeviceIDs.contains(
            device.id
        )
    }
   
    // MARK: - Controle Tuya Cloud

    func toggleCloud(
        _ device: Device
    ) async {


        guard let index = devices.firstIndex(where: {
            $0.id == device.id
        }) else {
            return
        }


        guard !pendingDeviceIDs.contains(device.id) else {
            return
        }


        let deviceToControl = devices[index]

        let desiredState = !deviceToControl.isOn


        pendingDeviceIDs.insert(device.id)

        lastCommandError = nil


        defer {
            pendingDeviceIDs.remove(device.id)
        }



        do {


            guard let deviceID = deviceToControl.virtualID,
                  !deviceID.isEmpty else {

                lastCommandError = "Sem Device ID Tuya"
                return
            }



            try await TuyaCloudService.shared.sendCommand(
                deviceID: deviceID,
                state: desiredState
            )



            print(
                "Comando enviado:",
                device.name,
                desiredState ? "LIGADO" : "DESLIGADO"
            )


            // aguarda o dispositivo atualizar na nuvem
            try await Task.sleep(
                for: .seconds(1)
            )


            // busca estado real
            refreshDeviceStates()



        } catch {


            lastCommandError =
            error.localizedDescription


            print(
                "Erro Tuya Cloud:",
                error.localizedDescription
            )
        }
    }
    
    
    
    // MARK: - Controle do dispositivo

    func toggle(
        _ device: Device
    ) {
        guard let index = devices.firstIndex(where: {
            $0.id == device.id
        }) else {
            return
        }

        guard !pendingDeviceIDs.contains(
            device.id
        ) else {
            return
        }

        let deviceToControl = devices[index]
        let desiredState = !deviceToControl.isOn

        pendingDeviceIDs.insert(
            device.id
        )

        lastCommandError = nil

        Task {
            defer {
                pendingDeviceIDs.remove(
                    device.id
                )
            }

            do {
                try await NovaDigitalService.shared.setPower(
                    desiredState,
                    device: deviceToControl
                )

                guard let updatedIndex = devices.firstIndex(where: {
                    $0.id == device.id
                }) else {
                    return
                }

                var updatedDevice = devices[updatedIndex]
                updatedDevice.isOn = desiredState

                update(updatedDevice)

            } catch {
                lastCommandError =
                    error.localizedDescription

                print(
                    "Erro enviando comando:",
                    error.localizedDescription
                )
            }
        }
    }
    
    // MARK: - Estado Real Cloud

    func refreshDeviceStates() {

        Task {

            let currentDevices = devices


            for device in currentDevices {

                do {

                    guard let virtualID = device.virtualID else {

                        print(
                            "Dispositivo sem VirtualID:",
                            device.name
                        )

                        continue
                    }


                    let state =
                    try await TuyaCloudService.shared.getStatus(
                        deviceID: virtualID
                    )


                    await MainActor.run {


                        guard let index =
                                devices.firstIndex(where: {
                                    $0.id == device.id
                                })
                        else {
                            return
                        }



                        var updatedDevice =
                        devices[index]



                        updatedDevice.isOn = state



                        update(updatedDevice)



                        print(
                            "Estado atualizado:",
                            device.name,
                            state ? "LIGADO" : "DESLIGADO"
                        )
                    }


                } catch {


                    print(
                        "Erro buscando estado:",
                        device.name,
                        error
                    )

                }
            }
        }
    }
    // MARK: - Buscar dispositivos


    func load() {


        let descriptor =
        FetchDescriptor<DeviceEntity>(
            sortBy: [
                SortDescriptor(
                    \.name
                )
            ]
        )



        do {

            let entities =
            try context.fetch(
                descriptor
            )


            devices = entities.map {

                let device = $0.toDevice()

                print("==============================")
                print("BANCO")
                print("Nome:", device.name)
                print("IP:", device.ip ?? "SEM IP")
                print("VirtualID:", device.virtualID ?? "SEM ID")
                print("ProductID:", device.productID ?? "SEM PRODUTO")
                print("LocalKey:", device.localKey ?? "SEM KEY")
                print("==============================")


                return device
            }


        } catch {


            print(
                "Erro carregando dispositivos:",
                error
            )


        }


    }





    // MARK: - Adicionar


    func add(
        _ device: Device
    ) {
        print("==============================")
        print("DEVICESTORE RECEBEU")
        print("Nome:", device.name)
        print("IP:", device.ip ?? "SEM IP")
        print("VirtualID:", device.virtualID ?? "SEM ID")
        print("LocalKey:", device.localKey ?? "SEM KEY")
        print("==============================")

        let entity =
        DeviceEntity(
            device: device
        )


        context.insert(
            entity
        )


        save()


        load()

    }






    // MARK: - Atualizar


    func update(
        _ device: Device
    ) {



        let deviceID: UUID = device.id


        let descriptor =
        FetchDescriptor<DeviceEntity>(
            predicate: #Predicate<DeviceEntity> { entity in
                entity.id == deviceID
            }
        )



        do {


            if let entity = try context.fetch( descriptor )
                .first {

                entity.name = device.name


                entity.room = device.room


                entity.isOn = device.isOn


                entity.online = device.online


                entity.ip = device.ip


                entity.mac = device.mac

                entity.virtualID = device.virtualID

                entity.productID = device.productID

                entity.localKey = device.localKey

                entity.signal = device.signal

                save()

                if let index = devices.firstIndex(where: {
                    $0.id == device.id
                }) {

                    devices[index] = device
                }

            }


        } catch {


            print(
                error
            )

        }


    }






    // MARK: - Remover


    func delete(
        _ device: Device
    ) {


        let deviceID: UUID = device.id


        let descriptor =
        FetchDescriptor<DeviceEntity>(
            predicate: #Predicate<DeviceEntity> { entity in
                entity.id == deviceID
            }
        )



        do {


            if let entity =
                try context.fetch(
                    descriptor
                )
                .first {


                context.delete(
                    entity
                )


                save()

                load()

            }


        } catch {


            print(
                error
            )


        }


    }






    // MARK: - Salvar


    private func save() {


        do {


            try context.save()


        } catch {


            print(
                "Erro salvando:",
                error
            )


        }

    }


}
