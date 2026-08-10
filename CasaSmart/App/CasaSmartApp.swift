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

    private let container: ModelContainer

    @StateObject
    private var store: DeviceStore

    init() {
        let container = try! ModelContainer(
            for: DeviceEntity.self
        )

        self.container = container

        _store = StateObject(
            wrappedValue: DeviceStore(
                context: container.mainContext
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .modelContainer(container)
    }
}
