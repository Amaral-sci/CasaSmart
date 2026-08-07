//
//  DevicePersistence.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 07/08/26.
//

import Foundation
import SwiftData


@MainActor
final class DevicePersistence {


    static let shared = DevicePersistence()



    private init(){}



    func save(
        _ device: Device,
        context: ModelContext
    ) {


        let entity =
        DeviceEntity(
            device: device
        )


        context.insert(entity)


        try? context.save()

    }





    func delete(
        _ device: Device,
        context: ModelContext
    ) {


        let descriptor =
        FetchDescriptor<DeviceEntity>()


        if let devices =
            try? context.fetch(descriptor)
        {


            if let item =
                devices.first(
                    where: {
                        $0.id == device.id
                    }
                )
            {


                context.delete(item)

                try? context.save()

            }

        }


    }




    func load(
        context: ModelContext
    ) -> [Device] {


        let descriptor =
        FetchDescriptor<DeviceEntity>()



        guard let entities =
                try? context.fetch(descriptor)

        else {

            return []

        }



        return entities.map {
            $0.toDevice()
        }


    }

}
