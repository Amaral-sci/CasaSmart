//
//  ContentView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    var body: some View {
        HomeView()
    }
}

#Preview {
    let container = try! ModelContainer(
        for: DeviceEntity.self,
        configurations: ModelConfiguration(
            isStoredInMemoryOnly: true
        )
    )

    let store = DeviceStore(
        context: container.mainContext
    )

    ContentView()
        .environmentObject(store)
        .modelContainer(container)
}
