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
    private let apiClient: APIClient

    // MARK: - ViewModels (Shared)

    @StateObject private var collectionViewModel: CollectionViewModel
    @StateObject private var syncViewModel: SyncViewModel
    @StateObject private var cardSearchViewModel: CardSearchViewModel

    // MARK: - Initialization

    init() {
        // Initialize services
        let dbService = try! DatabaseService()
        let api = APIClient()

        self.databaseService = dbService
        self.apiClient = api

        // Initialize ViewModels with dependencies
        _collectionViewModel = StateObject(wrappedValue: CollectionViewModel(databaseService: dbService))
        _syncViewModel = StateObject(wrappedValue: SyncViewModel(databaseService: dbService, apiClient: api))
        _cardSearchViewModel = StateObject(wrappedValue: CardSearchViewModel(databaseService: dbService))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(collectionViewModel)
                .environmentObject(syncViewModel)
                .environmentObject(cardSearchViewModel)
                .task {
                    // Print Documents directory for debugging
                    print("📂 Documents directory: \(ImageHelper.documentsPath())")

                    // Ensure default folders exist on first launch
                    try? await databaseService.ensureDefaultFolders()
                }
        }
    }
}
