//
//  ScanAndImportView.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 12/8/24.
//

import SwiftUI
import UniformTypeIdentifiers

/// Main view for scanning QR codes and importing decks/collections
struct ScanAndImportView: View {
    @EnvironmentObject var collectionViewModel: CollectionViewModel
    @EnvironmentObject var deckViewModel: DeckViewModel

    @State private var showingScanner = false
    @State private var showingImportDialog = false
    @State private var scannedURL: String?
    @State private var sharedList: SharedListResponse?
    @State private var isLoadingSharedList = false
    @State private var errorMessage: String?
    @State private var showingCSVImport = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // QR Code Icon
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 100))
                    .foregroundColor(.blue)

                // Title
                Text("Import Deck or Collection")
                    .font(.title)
                    .fontWeight(.bold)

                // Description
                Text("Scan a QR code from get-diced.com or import from a CSV file")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Scan Button
                Button(action: {
                    showingScanner = true
                }) {
                    Label("Scan QR Code", systemImage: "camera")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                // CSV Import Button
                Button(action: {
                    showingCSVImport = true
                }) {
                    Label("Import from CSV", systemImage: "doc.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Import")
            .sheet(isPresented: $showingScanner) {
                QRCodeScannerView { scannedCode in
                    handleScannedCode(scannedCode)
                }
            }
            .sheet(isPresented: $showingImportDialog) {
                if let sharedList = sharedList {
                    ImportSelectionView(
                        sharedList: sharedList,
                        onImport: { destinationId in
                            Task {
                                await performImport(sharedList: sharedList, destinationId: destinationId)
                            }
                        },
                        onCancel: {
                            showingImportDialog = false
                            self.sharedList = nil
                        }
                    )
                } else if isLoadingSharedList {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading shared list...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .fileImporter(
                isPresented: $showingCSVImport,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    guard let fileURL = files.first else { return }
                    guard fileURL.startAccessingSecurityScopedResource() else { return }
                    defer { fileURL.stopAccessingSecurityScopedResource() }

                    do {
                        let csvData = try String(contentsOf: fileURL, encoding: .utf8)
                        // Show dialog to select import type and destination
                        handleCSVImport(csvData: csvData, filename: fileURL.lastPathComponent)
                    } catch {
                        errorMessage = "Failed to read CSV file: \(error.localizedDescription)"
                    }
                case .failure(let error):
                    errorMessage = "Failed to select file: \(error.localizedDescription)"
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }

    private func handleCSVImport(csvData: String, filename: String) {
        // TODO: Show dialog to ask if it's a deck or collection
        // For now, detect based on header
        if csvData.contains("Slot Type") {
            // It's a deck CSV
            errorMessage = "Deck CSV import coming soon. Use the Decks tab export menu to import CSV files."
        } else {
            // It's a collection CSV
            errorMessage = "Collection CSV import coming soon. Use the Collection folder menu to import CSV files."
        }
    }

    private func handleScannedCode(_ code: String) {
        scannedURL = code

        // Extract shared list ID
        guard let sharedListId = deckViewModel.extractSharedListId(from: code) else {
            errorMessage = "Invalid QR code. Expected a get-diced.com shared list URL."
            return
        }

        // Fetch shared list from API
        Task {
            isLoadingSharedList = true
            showingImportDialog = true

            do {
                let apiClient = APIClient()
                let fetchedList = try await apiClient.getSharedList(byId: sharedListId)
                sharedList = fetchedList
            } catch {
                errorMessage = "Failed to load shared list: \(error.localizedDescription)"
                showingImportDialog = false
            }

            isLoadingSharedList = false
        }
    }

    private func performImport(sharedList: SharedListResponse, destinationId: String) async {
        guard let sharedListId = deckViewModel.extractSharedListId(from: scannedURL ?? "") else {
            return
        }

        if sharedList.listType == "DECK" {
            await deckViewModel.importDeckFromSharedList(sharedListId: sharedListId, toFolderId: destinationId)
        } else if sharedList.listType == "COLLECTION" {
            await collectionViewModel.importCollectionFromSharedList(sharedListId: sharedListId, toFolderId: destinationId)
        }

        showingImportDialog = false
        self.sharedList = nil
    }
}

/// Dialog for selecting import destination
struct ImportSelectionView: View {
    let sharedList: SharedListResponse
    let onImport: (String) -> Void
    let onCancel: () -> Void

    @EnvironmentObject var collectionViewModel: CollectionViewModel
    @EnvironmentObject var deckViewModel: DeckViewModel

    @State private var selectedFolderId: String?

    var body: some View {
        NavigationStack {
            List {
                // Info Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        if let name = sharedList.name {
                            Text(name)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }

                        HStack {
                            Label(sharedList.listType == "DECK" ? "Deck" : "Collection", systemImage: sharedList.listType == "DECK" ? "rectangle.stack" : "folder")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("\(sharedList.cardUuids.count) cards")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if let description = sharedList.description, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Destination Selection
                Section("Select Destination") {
                    if sharedList.listType == "DECK" {
                        ForEach(deckViewModel.deckFolders) { folder in
                            Button(action: {
                                selectedFolderId = folder.id
                            }) {
                                HStack {
                                    Text(folder.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedFolderId == folder.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(collectionViewModel.folders) { folder in
                            Button(action: {
                                selectedFolderId = folder.id
                            }) {
                                HStack {
                                    Text(folder.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedFolderId == folder.id {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        if let folderId = selectedFolderId {
                            onImport(folderId)
                        }
                    }
                    .disabled(selectedFolderId == nil)
                }
            }
            .task {
                // Load folders if needed
                if sharedList.listType == "DECK" {
                    await deckViewModel.loadDeckFolders()
                    // Pre-select first deck folder
                    selectedFolderId = deckViewModel.deckFolders.first?.id
                } else {
                    await collectionViewModel.loadFolders()
                    // Pre-select first collection folder
                    selectedFolderId = collectionViewModel.folders.first?.id
                }
            }
        }
    }
}

#Preview {
    ScanAndImportView()
        .environmentObject(CollectionViewModel(databaseService: try! DatabaseService()))
        .environmentObject(DeckViewModel(databaseService: try! DatabaseService()))
}
