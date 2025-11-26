//
//  GetDicedApp.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 11/25/25.
//

import SwiftUI

@main
struct GetDicedApp: App {

    // MARK: - Services (Singleton)

    private let databaseService: DatabaseService

    // MARK: - ViewModels (Shared)

    @StateObject private var collectionViewModel: CollectionViewModel

    // MARK: - Initialization

    init() {
        // Initialize services
        let dbService = try! DatabaseService()
        self.databaseService = dbService

        // Initialize ViewModels with dependencies
        _collectionViewModel = StateObject(wrappedValue: CollectionViewModel(databaseService: dbService))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(collectionViewModel)
                .task {
                    // Print Documents directory for debugging
                    print("📂 Documents directory: \(ImageHelper.documentsPath())")

                    // Ensure default folders exist on first launch
                    try? await databaseService.ensureDefaultFolders()
                }
        }
    }
}
