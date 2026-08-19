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

            Task { @MainActor in

                pendingDeviceIDs.remove(device.id)

            }
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

            var updatedDevice = deviceToControl

            updatedDevice.isOn = desiredState


            update(updatedDevice)


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



            devices =
            entities.map {
                $0.toDevice()
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


                load()

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
