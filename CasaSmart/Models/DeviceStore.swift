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



    @Published
    var devices: [Device] = []



    init(
        context: ModelContext
    ) {

        self.context = context

        load()

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


        // altera estado local

        devices[index].isOn.toggle()


        // salva no banco

        update(
            devices[index]
        )


        // envia comando físico

        Task {

            do {

                try await NovaDigitalService.shared.toggle(
                    device: devices[index]
                )


            } catch {

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


            if let entity =
                try context.fetch(
                    descriptor
                )
                .first {


                entity.name =
                device.name


                entity.room =
                device.room


                entity.isOn =
                device.isOn


                entity.online =
                device.online


                entity.ip =
                device.ip


                entity.mac =
                device.mac



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
