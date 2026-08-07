//
//  ContentView.swift
//  CasaSmart
//
//  Created by Jonathan Amaral on 06/08/26.
//

import SwiftUI
import SwiftData


struct ContentView: View {


    @Environment(\.modelContext)
    private var context


    @StateObject
    private var store: DeviceStore



    init() {


        let container =
        try! ModelContainer(
            for: DeviceEntity.self
        )


        _store =
        StateObject(
            wrappedValue:
                DeviceStore(
                    context:
                        container.mainContext
                )
        )


    }



    var body: some View {


        HomeView()

            .environmentObject(
                store
            )


    }


}


#Preview {


    ContentView()

        .modelContainer(
            for: DeviceEntity.self,
            inMemory: true
        )


}
