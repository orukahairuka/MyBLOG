//
//  ContentView.swift
//  MyBLOG
//
//  Created by 櫻井絵理香 on 2024/08/13.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var apiClient = NotionApiClient()

    var body: some View {
        NavigationView {
            List {
                if apiClient.isLoading {
                    ProgressView("Loading...")
                } else if let error = apiClient.error {
                    Text("Error: \(error.localizedDescription)")
                } else if let database = apiClient.database {
                    Section(header: Text("Database Info")) {
                        Text("Title: \(database.title.first?.plainText ?? "N/A")")
                        Text("ID: \(database.id)")
                        Text("Created: \(database.createdTime)")
                    }

                    Section(header: Text("Properties")) {
                        Text("タグ: \(database.properties.タグ.type)")
                        Text("名前: \(database.properties.名前.type)")
                    }
                } else {
                    Text("No data available")
                }
            }
            .navigationTitle("Notion Database")
            .onAppear {
                apiClient.fetchDatabase(id: "c5a35870426c49f0b7669991b1c92fa6")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
