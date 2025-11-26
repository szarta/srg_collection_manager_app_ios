//
//  ContentView.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 11/25/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                FoldersView()
            }
            .tabItem {
                Label("Collection", systemImage: "folder")
            }

            NavigationStack {
                CardSearchView()
            }
            .tabItem {
                Label("Viewer", systemImage: "rectangle.grid.2x2")
            }

            NavigationStack {
                DecksView()
            }
            .tabItem {
                Label("Decks", systemImage: "square.stack.3d.up")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

// MARK: - FoldersView

struct FoldersView: View {
    @EnvironmentObject var viewModel: CollectionViewModel
    @State private var showAddFolder = false

    var body: some View {
        List {
            // Default folders section
            Section("Default Folders") {
                ForEach(defaultFolders) { folder in
                    NavigationLink(value: folder) {
                        FolderRow(folder: folder)
                    }
                }
            }

            // Custom folders section
            if !customFolders.isEmpty {
                Section("Custom Folders") {
                    ForEach(customFolders) { folder in
                        NavigationLink(value: folder) {
                            FolderRow(folder: folder)
                        }
                    }
                    .onDelete(perform: deleteFolder)
                }
            }
        }
        .navigationTitle("Collection")
        .navigationDestination(for: Folder.self) { folder in
            FolderDetailView(folder: folder)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddFolder = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddFolder) {
            AddFolderSheet()
        }
        .task {
            await viewModel.loadFolders()
        }
        .overlay {
            if viewModel.isLoading && viewModel.folders.isEmpty {
                ProgressView("Loading folders...")
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }

    var defaultFolders: [Folder] {
        viewModel.folders.filter { $0.isDefault }
    }

    var customFolders: [Folder] {
        viewModel.folders.filter { !$0.isDefault }
    }

    func deleteFolder(at offsets: IndexSet) {
        let foldersToDelete = offsets.map { customFolders[$0] }
        Task {
            for folder in foldersToDelete {
                await viewModel.deleteFolder(folder)
            }
        }
    }
}

// MARK: - FolderRow

struct FolderRow: View {
    let folder: Folder

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: folder.isDefault ? "folder.fill" : "folder")
                .foregroundStyle(folder.isDefault ? .blue : .gray)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(folder.name)
                    .font(.body)

                if folder.isDefault {
                    Text("System Folder")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Folder Sheet

struct AddFolderSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: CollectionViewModel
    @State private var folderName = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Folder Name", text: $folderName)
                } footer: {
                    Text("Create a custom folder to organize your cards.")
                }
            }
            .navigationTitle("New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await viewModel.createFolder(name: folderName)
                            dismiss()
                        }
                    }
                    .disabled(folderName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - FolderDetailView

struct FolderDetailView: View {
    let folder: Folder
    @EnvironmentObject var viewModel: CollectionViewModel
    @State private var showAddCard = false
    @State private var selectedCard: Card?
    @State private var showEditQuantity = false

    var body: some View {
        Group {
            if viewModel.cardsInFolder.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                cardsList
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Card.self) { card in
            CardDetailView(card: card)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddCard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCard) {
            AddCardToFolderSheet(folder: folder)
        }
        .sheet(isPresented: $showEditQuantity) {
            if let card = selectedCard {
                EditQuantitySheet(card: card, folder: folder)
            }
        }
        .task {
            await viewModel.selectFolder(folder)
        }
        .overlay {
            if viewModel.isLoading && viewModel.cardsInFolder.isEmpty {
                ProgressView("Loading cards...")
            }
        }
    }

    var cardsList: some View {
        List {
            ForEach(viewModel.cardsInFolder, id: \.card.id) { item in
                NavigationLink(value: item.card) {
                    CardRow(card: item.card, quantity: item.quantity)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Delete", role: .destructive) {
                        Task {
                            await viewModel.removeCard(item.card, fromFolder: folder.id)
                        }
                    }

                    Button {
                        selectedCard = item.card
                        showEditQuantity = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .contextMenu {
                    Button {
                        selectedCard = item.card
                        showEditQuantity = true
                    } label: {
                        Label("Edit Quantity", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        Task {
                            await viewModel.removeCard(item.card, fromFolder: folder.id)
                        }
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 60))
                .foregroundStyle(.gray)

            Text("No Cards")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add cards to this folder using the + button")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Add Card") {
                showAddCard = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Edit Quantity Sheet

struct EditQuantitySheet: View {
    let card: Card
    let folder: Folder
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: CollectionViewModel
    @State private var quantity: Int = 1

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CardRow(card: card)
                } header: {
                    Text("Card")
                }

                Section {
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                } header: {
                    Text("Quantity")
                }
            }
            .navigationTitle("Edit Quantity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.updateQuantity(
                                card: card,
                                inFolder: folder.id,
                                newQuantity: quantity
                            )
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                // Get current quantity
                if let item = viewModel.cardsInFolder.first(where: { $0.card.id == card.id }) {
                    quantity = item.quantity
                }
            }
        }
    }
}

// MARK: - Add Card to Folder Sheet

struct AddCardToFolderSheet: View {
    let folder: Folder
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: CollectionViewModel
    @State private var searchQuery = ""
    @State private var searchResults: [Card] = []
    @State private var isSearching = false
    @State private var selectedCard: Card?
    @State private var quantity: Int = 1

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let card = selectedCard {
                    // Show selected card and quantity picker
                    selectedCardView(card: card)
                } else {
                    // Show search results
                    searchResultsView
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Search cards...")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if selectedCard != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            Task {
                                if let card = selectedCard {
                                    await viewModel.addCard(card, toFolder: folder.id, quantity: quantity)
                                }
                                dismiss()
                            }
                        }
                    }
                }
            }
            .onChange(of: searchQuery) { newValue in
                Task {
                    await performSearch(query: newValue)
                }
            }
            .task {
                // Load initial cards
                await performSearch(query: "")
            }
        }
    }

    @ViewBuilder
    func selectedCardView(card: Card) -> some View {
        Form {
            Section {
                CardRow(card: card)
            } header: {
                Text("Selected Card")
            }

            Section {
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
            } header: {
                Text("Quantity")
            }

            Section {
                Button("Change Card") {
                    selectedCard = nil
                }
            }
        }
    }

    var searchResultsView: some View {
        Group {
            if isSearching {
                ProgressView("Searching...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResults.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundStyle(.gray)

                    Text("No Results")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Try a different search term")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(searchResults) { card in
                    CardRow(card: card)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCard = card
                        }
                }
            }
        }
    }

    func performSearch(query: String) async {
        isSearching = true

        do {
            let dbService = viewModel.databaseService
            if query.isEmpty {
                // Show first 50 cards
                searchResults = try await dbService.searchCards(
                    query: nil,
                    cardType: nil,
                    atkType: nil,
                    playOrder: nil,
                    division: nil,
                    releaseSet: nil,
                    isBanned: nil,
                    limit: 50
                )
            } else {
                // Search by name
                searchResults = try await dbService.searchCards(query: query, limit: 50)
            }
        } catch {
            print("Search error: \(error)")
            searchResults = []
        }

        isSearching = false
    }
}

// MARK: - CardDetailView

struct CardDetailView: View {
    let card: Card
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Card Image
                cardImage

                // Basic Info Section
                infoSection

                // Stats Section (if applicable)
                if hasStats {
                    statsSection
                }

                // Rules Text Section
                if let rulesText = card.rulesText {
                    rulesSection(rulesText)
                }

                // Errata Section
                if let errataText = card.errataText {
                    errataSection(errataText)
                }

                // Additional Info
                additionalInfoSection
            }
            .padding()
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if let srgUrl = card.srgUrl, let url = URL(string: srgUrl) {
                        Link(destination: url) {
                            Label("View on SRG Website", systemImage: "safari")
                        }
                    }

                    if let srgpcUrl = card.srgpcUrl, let url = URL(string: srgpcUrl) {
                        Link(destination: url) {
                            Label("View on SRGPC", systemImage: "link")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    var cardImage: some View {
        Group {
            if let imageURL = ImageHelper.imageURL(for: card.id) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: 300)
                            .aspectRatio(0.714, contentMode: .fit)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 300)
                            .cornerRadius(12)
                            .shadow(radius: 4)
                    case .failure:
                        cardImagePlaceholder
                    @unknown default:
                        cardImagePlaceholder
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                cardImagePlaceholder
                    .frame(maxWidth: .infinity)
            }
        }
    }

    var cardImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.gray.opacity(0.2))
            .aspectRatio(0.714, contentMode: .fit)
            .frame(maxWidth: 300)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.gray)
                    Text("Card Image")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
    }

    var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(card.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                if card.isBanned {
                    Label("Banned", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.red)
                        .cornerRadius(8)
                }
            }

            LabeledContent("Card Type", value: card.cardType)

            if let releaseSet = card.releaseSet {
                LabeledContent("Release Set", value: releaseSet)
            }

            if let division = card.division {
                LabeledContent("Division", value: division)
            }

            if let gender = card.gender {
                LabeledContent("Gender", value: gender)
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    var hasStats: Bool {
        card.power != nil || card.agility != nil || card.strike != nil ||
        card.submission != nil || card.grapple != nil || card.technique != nil
    }

    var statsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stats")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let power = card.power {
                    StatBadge(label: "Power", value: power, color: .red)
                }
                if let agility = card.agility {
                    StatBadge(label: "Agility", value: agility, color: .blue)
                }
                if let strike = card.strike {
                    StatBadge(label: "Strike", value: strike, color: .orange)
                }
                if let submission = card.submission {
                    StatBadge(label: "Submission", value: submission, color: .purple)
                }
                if let grapple = card.grapple {
                    StatBadge(label: "Grapple", value: grapple, color: .green)
                }
                if let technique = card.technique {
                    StatBadge(label: "Technique", value: technique, color: .indigo)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    func rulesSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rules Text")
                .font(.headline)

            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }

    func errataSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Errata", systemImage: "exclamationmark.circle")
                .font(.headline)
                .foregroundStyle(.orange)

            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.orange.opacity(0.1))
        .cornerRadius(12)
    }

    var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Info")
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                if let atkType = card.atkType {
                    LabeledContent("Attack Type", value: atkType)
                }

                if let playOrder = card.playOrder {
                    LabeledContent("Play Order", value: playOrder)
                }

                if let deckCardNumber = card.deckCardNumber {
                    LabeledContent("Deck Card Number", value: String(deckCardNumber))
                }

                if let comments = card.comments {
                    LabeledContent("Comments", value: comments)
                }

                if let tags = card.tags {
                    LabeledContent("Tags", value: tags)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(12)
    }
}

// MARK: - StatBadge

struct StatBadge: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - CardRow

struct CardRow: View {
    let card: Card
    let quantity: Int?

    init(card: Card, quantity: Int? = nil) {
        self.card = card
        self.quantity = quantity
    }

    var body: some View {
        HStack(spacing: 12) {
            // Card image
            if let imageURL = ImageHelper.imageURL(for: card.id) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 84)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    case .failure:
                        placeholderImage
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }

            // Card info
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text(card.cardType)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if card.isBanned {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                if let set = card.releaseSet {
                    Text(set)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Quantity badge
            if let qty = quantity {
                Text("×\(qty)")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }

    var placeholderImage: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(.gray.opacity(0.3))
            .frame(width: 60, height: 84)
            .overlay {
                VStack(spacing: 2) {
                    Image(systemName: "photo")
                        .foregroundStyle(.gray)
                    if let cardType = card.cardType.split(separator: " ").first {
                        Text(String(cardType))
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                }
            }
    }
}

// MARK: - Placeholder Views

struct CardSearchView: View {
    var body: some View {
        Text("Viewer")
            .navigationTitle("Card Viewer")
    }
}

struct DecksView: View {
    var body: some View {
        Text("Decks")
            .navigationTitle("Decks")
    }
}

struct SettingsView: View {
    @EnvironmentObject var syncViewModel: SyncViewModel
    @State private var showingSyncOptions = false

    var body: some View {
        Form {
            // App Info Section
            Section("App Information") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")
                LabeledContent("Bundle ID", value: "com.srg.GetDiced")
            }

            // Database Section
            Section("Database") {
                LabeledContent("Current Version", value: "v\(syncViewModel.currentDatabaseVersion)")

                if let latest = syncViewModel.latestDatabaseVersion {
                    LabeledContent("Latest Version", value: "v\(latest)")
                }

                if syncViewModel.updateAvailable {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Update Available")
                            .foregroundStyle(.orange)
                    }
                }

                Button {
                    Task {
                        await syncViewModel.checkForUpdates()
                    }
                } label: {
                    HStack {
                        Text("Check for Updates")
                        if syncViewModel.isSyncing {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(syncViewModel.isSyncing)

                if syncViewModel.updateAvailable {
                    Button {
                        showingSyncOptions = true
                    } label: {
                        Label("Sync Database", systemImage: "arrow.down.circle.fill")
                    }
                    .disabled(syncViewModel.isSyncing)
                }

                if let lastSync = syncViewModel.lastSyncDate {
                    LabeledContent("Last Synced", value: lastSync.formatted(date: .abbreviated, time: .shortened))
                }
            }

            // Images Section
            Section("Card Images") {
                if syncViewModel.totalImages > 0 {
                    LabeledContent("Total Cards", value: "\(syncViewModel.totalImages)")
                    LabeledContent("Downloaded", value: "\(syncViewModel.downloadedImages)")
                }

                Button {
                    Task {
                        await syncViewModel.syncImages()
                    }
                } label: {
                    HStack {
                        Text("Download Missing Images")
                        if syncViewModel.isSyncing {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(syncViewModel.isSyncing)
            }

            // Sync Progress
            if syncViewModel.isSyncing {
                Section("Sync Progress") {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: syncViewModel.syncProgress)
                        Text(syncViewModel.syncMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Status Messages
            if !syncViewModel.syncMessage.isEmpty && !syncViewModel.isSyncing {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(syncViewModel.syncMessage)
                            .font(.callout)
                    }
                }
            }

            // Storage Section
            Section("Storage") {
                LabeledContent("Documents Path") {
                    Text(ImageHelper.documentsPath())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            // Links Section
            Section("Links") {
                Link(destination: URL(string: "https://srgsupershow.com")!) {
                    HStack {
                        Label("SRG Website", systemImage: "safari")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://get-diced.com")!) {
                    HStack {
                        Label("Get-Diced.com", systemImage: "globe")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // About Section
            Section("About") {
                Text("Get Diced is the unofficial companion app for the SRG Universe trading card game. Manage your collection, build decks, and browse all cards.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .alert("Sync Database?", isPresented: $showingSyncOptions) {
            Button("Cancel", role: .cancel) { }
            Button("Sync Now") {
                Task {
                    await syncViewModel.syncDatabase()
                }
            }
        } message: {
            Text("This will update your card database to v\(syncViewModel.latestDatabaseVersion ?? 0). Your collection and decks will be preserved.")
        }
        .alert("Error", isPresented: .constant(syncViewModel.errorMessage != nil)) {
            Button("OK") {
                syncViewModel.errorMessage = nil
            }
        } message: {
            if let error = syncViewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            // Check for updates on load
            await syncViewModel.checkForUpdates()
        }
    }
}

#Preview {
    ContentView()
}
