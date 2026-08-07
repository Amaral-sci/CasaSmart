//
//  CasaSmartApp.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//
import SwiftUI
import SwiftData


@main
struct CasaSmartApp: App {


    var body: some Scene {


        WindowGroup {


            ContentView()


        }
        .modelContainer(
            for: DeviceEntity.self
        )


    }

}
