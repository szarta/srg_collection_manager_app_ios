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
    @State private var cardToView: Card?

    var body: some View {
        NavigationStack {
            searchResultsView
                .navigationTitle("Add Card")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchQuery, prompt: "Search cards...")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                .toolbar(.visible, for: .navigationBar)
            .sheet(item: $cardToView) { card in
                NavigationStack {
                    CardDetailWithQuantityView(
                        card: card,
                        folder: folder,
                        onDismiss: { cardToView = nil },
                        onAdd: { quantity in
                            Task {
                                await viewModel.addCard(card, toFolder: folder.id, quantity: quantity)
                                cardToView = nil
                                dismiss()
                            }
                        }
                    )
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
                            cardToView = card
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

// MARK: - Card Detail with Quantity (for adding to collection)

struct CardDetailWithQuantityView: View {
    let card: Card
    let folder: Folder
    let onDismiss: () -> Void
    let onAdd: (Int) -> Void

    @State private var quantity: Int = 1

    var body: some View {
        VStack(spacing: 0) {
            // Card detail in scrollable area
            CardDetailView(card: card, showToolbarLink: false)

            // Quantity picker at bottom (always visible)
            VStack(spacing: 0) {
                Divider()

                HStack {
                    Text("Quantity")
                        .font(.headline)

                    Spacer()

                    Stepper("\(quantity)", value: $quantity, in: 1...99)
                        .labelsHidden()

                    Text("\(quantity)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .frame(minWidth: 40, alignment: .trailing)
                }
                .padding()
                .background(.regularMaterial)
            }
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") {
                    onDismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    onAdd(quantity)
                }
            }
        }
    }
}

// MARK: - CardDetailView

struct CardDetailView: View {
    let card: Card
    var showToolbarLink: Bool = true
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

                // Web link (when not in toolbar)
                if !showToolbarLink {
                    webLinkSection
                }
            }
            .padding()
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showToolbarLink {
                ToolbarItem(placement: .primaryAction) {
                    let getDicedUrl = URL(string: "https://get-diced.com/card/\(card.id)")!
                    Link(destination: getDicedUrl) {
                        Label("View on get-diced.com", systemImage: "safari")
                    }
                }
            }
        }
    }

    var webLinkSection: some View {
        VStack(spacing: 12) {
            let getDicedUrl = URL(string: "https://get-diced.com/card/\(card.id)")!
            Link(destination: getDicedUrl) {
                HStack {
                    Image(systemName: "safari")
                    Text("View on get-diced.com")
                    Spacer()
                    Image(systemName: "arrow.up.forward.square")
                        .font(.caption)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(12)
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

// MARK: - Card Search/Viewer Tab

struct CardSearchView: View {
    @EnvironmentObject var viewModel: CardSearchViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Filter Chips
                if viewModel.hasActiveFilters {
                    ActiveFiltersBar(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                }

                // Results count
                HStack {
                    Text("\(viewModel.cards.count) cards")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // Card Grid
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if viewModel.cards.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No cards found")
                            .font(.headline)
                        Text("Try adjusting your filters")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(viewModel.cards) { card in
                            NavigationLink(value: card) {
                                CardGridItem(card: card)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle("Card Viewer")
        .navigationDestination(for: Card.self) { card in
            CardDetailView(card: card)
        }
        .searchable(text: $viewModel.searchQuery, prompt: "Search cards...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    FiltersMenu(viewModel: viewModel)
                } label: {
                    Label("Filters", systemImage: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .task {
            // Load filter options and initial cards
            await viewModel.loadFilterOptions()
            await viewModel.loadInitialCards()
        }
    }
}

// MARK: - Card Grid Item

struct CardGridItem: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Card Image
            if let imageURL = ImageHelper.imageURL(for: card.id) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(0.72, contentMode: .fit)
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(0.72, contentMode: .fit)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            }
                            .cornerRadius(8)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(0.72, contentMode: .fit)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    }
                    .cornerRadius(8)
            }

            // Card Name
            Text(card.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundColor(.primary)

            // Card Type
            Text(card.cardType)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Active Filters Bar

struct ActiveFiltersBar: View {
    @ObservedObject var viewModel: CardSearchViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Clear all button
                Button(action: {
                    viewModel.clearFilters()
                }) {
                    Label("Clear All", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(16)
                }

                // Active filter chips
                if let cardType = viewModel.selectedCardType {
                    FilterChip(label: cardType) {
                        viewModel.selectedCardType = nil
                    }
                }

                if let division = viewModel.selectedDivision {
                    FilterChip(label: division) {
                        viewModel.selectedDivision = nil
                    }
                }

                if let atkType = viewModel.selectedAtkType {
                    FilterChip(label: atkType) {
                        viewModel.selectedAtkType = nil
                    }
                }

                if let playOrder = viewModel.selectedPlayOrder {
                    FilterChip(label: playOrder) {
                        viewModel.selectedPlayOrder = nil
                    }
                }

                if let releaseSet = viewModel.selectedReleaseSet {
                    FilterChip(label: releaseSet) {
                        viewModel.selectedReleaseSet = nil
                    }
                }

                if viewModel.showBannedOnly {
                    FilterChip(label: "Banned") {
                        viewModel.showBannedOnly = false
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct FilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(16)
    }
}

// MARK: - Filters Menu

struct FiltersMenu: View {
    @ObservedObject var viewModel: CardSearchViewModel

    var body: some View {
        // Card Type
        Menu("Card Type") {
            Button("All Types") {
                viewModel.selectedCardType = nil
            }
            ForEach(viewModel.availableCardTypes, id: \.self) { type in
                Button(type) {
                    viewModel.selectedCardType = type
                }
            }
        }

        // Division
        Menu("Division") {
            Button("All Divisions") {
                viewModel.selectedDivision = nil
            }
            ForEach(viewModel.availableDivisions, id: \.self) { division in
                Button(division) {
                    viewModel.selectedDivision = division
                }
            }
        }

        // Attack Type
        Menu("Attack Type") {
            Button("All") {
                viewModel.selectedAtkType = nil
            }
            Button("Strike") {
                viewModel.selectedAtkType = "Strike"
            }
            Button("Grapple") {
                viewModel.selectedAtkType = "Grapple"
            }
            Button("Submission") {
                viewModel.selectedAtkType = "Submission"
            }
        }

        // Play Order
        Menu("Play Order") {
            Button("All") {
                viewModel.selectedPlayOrder = nil
            }
            Button("Before") {
                viewModel.selectedPlayOrder = "Before"
            }
            Button("During") {
                viewModel.selectedPlayOrder = "During"
            }
            Button("After") {
                viewModel.selectedPlayOrder = "After"
            }
        }

        Divider()

        // Banned Toggle
        Button(action: {
            viewModel.showBannedOnly.toggle()
        }) {
            Label(
                viewModel.showBannedOnly ? "Show All Cards" : "Show Banned Only",
                systemImage: viewModel.showBannedOnly ? "checkmark" : ""
            )
        }

        Divider()

        // Clear All
        Button("Clear All Filters", role: .destructive) {
            viewModel.clearFilters()
        }
    }
}

// MARK: - Placeholder Views

// MARK: - Decks Tab

struct DecksView: View {
    @EnvironmentObject var viewModel: DeckViewModel

    var body: some View {
        DeckFoldersView()
            .task {
                await viewModel.loadDeckFolders()
            }
    }
}

// MARK: - Deck Folders View

struct DeckFoldersView: View {
    @EnvironmentObject var viewModel: DeckViewModel
    @State private var showAddFolder = false
    @State private var newFolderName = ""

    var defaultFolders: [DeckFolder] {
        viewModel.deckFolders.filter { $0.isDefault }
    }

    var customFolders: [DeckFolder] {
        viewModel.deckFolders.filter { !$0.isDefault }
    }

    var body: some View {
        List {
            // Default Folders
            if !defaultFolders.isEmpty {
                Section("Default Folders") {
                    ForEach(defaultFolders) { folder in
                        NavigationLink(value: folder) {
                            DeckFolderRow(folder: folder)
                        }
                    }
                }
            }

            // Custom Folders
            if !customFolders.isEmpty {
                Section("My Folders") {
                    ForEach(customFolders) { folder in
                        NavigationLink(value: folder) {
                            DeckFolderRow(folder: folder)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let folder = customFolders[index]
                            Task {
                                await viewModel.deleteDeckFolder(folder)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Decks")
        .navigationDestination(for: DeckFolder.self) { folder in
            DeckListView(folder: folder)
        }
        .navigationDestination(for: Deck.self) { deck in
            DeckEditorView(deck: deck)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddFolder = true
                }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showAddFolder) {
            NavigationStack {
                Form {
                    TextField("Folder Name", text: $newFolderName)
                }
                .navigationTitle("New Deck Folder")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddFolder = false
                            newFolderName = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            Task {
                                await viewModel.createDeckFolder(name: newFolderName)
                                showAddFolder = false
                                newFolderName = ""
                            }
                        }
                        .disabled(newFolderName.isEmpty)
                    }
                }
            }
        }
    }
}

struct DeckFolderRow: View {
    let folder: DeckFolder

    var body: some View {
        HStack {
            Image(systemName: folder.isDefault ? "folder" : "folder.fill")
                .foregroundColor(.blue)
            Text(folder.name)
        }
    }
}

// MARK: - Deck List View

struct DeckListView: View {
    let folder: DeckFolder
    @EnvironmentObject var viewModel: DeckViewModel
    @State private var showAddDeck = false
    @State private var newDeckName = ""

    var body: some View {
        Group {
            if viewModel.decks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Decks")
                        .font(.headline)
                    Text("Tap + to create a deck")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.decks) { deckWithCount in
                        NavigationLink(value: deckWithCount.deck) {
                            DeckRowView(deck: deckWithCount.deck, cardCount: deckWithCount.cardCount)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let deck = viewModel.decks[index].deck
                            Task {
                                await viewModel.deleteDeck(deck)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showAddDeck = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadDecks(in: folder.id)
        }
        .sheet(isPresented: $showAddDeck) {
            NavigationStack {
                Form {
                    TextField("Deck Name", text: $newDeckName)
                }
                .navigationTitle("New Deck")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            showAddDeck = false
                            newDeckName = ""
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Create") {
                            Task {
                                await viewModel.createDeck(
                                    in: folder.id,
                                    name: newDeckName,
                                    spectacleType: .valiant  // Default to Valiant
                                )
                                showAddDeck = false
                                newDeckName = ""
                            }
                        }
                        .disabled(newDeckName.isEmpty)
                    }
                }
            }
        }
    }
}

struct DeckRowView: View {
    let deck: Deck
    let cardCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(deck.name)
                .font(.headline)
            HStack {
                Text(deck.spectacleType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(cardCount) cards")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Deck Editor View

struct DeckEditorView: View {
    let deck: Deck
    @EnvironmentObject var viewModel: DeckViewModel
    @State private var showingCardPicker = false
    @State private var selectedSlotType: DeckSlotType = .deck
    @State private var selectedSlotNumber: Int = 1

    var body: some View {
        List {
            // Spectacle Type
            Section("Spectacle Type") {
                if let currentDeck = viewModel.selectedDeck {
                    Picker("Type", selection: Binding(
                        get: { currentDeck.spectacleType },
                        set: { newType in
                            Task {
                                await viewModel.updateDeckSpectacleType(deck.id, spectacleType: newType)
                            }
                        }
                    )) {
                        Text("Valiant").tag(SpectacleType.valiant)
                        Text("Newman").tag(SpectacleType.newman)
                    }
                    .pickerStyle(.segmented)
                }
            }

            // Entrance
            Section("Entrance") {
                if let entrance = viewModel.entrance {
                    CardRow(card: entrance)
                } else {
                    Button(action: {
                        selectedSlotType = .entrance
                        showingCardPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Set Entrance")
                        }
                    }
                }
            }

            // Competitor
            Section("Competitor") {
                if let competitor = viewModel.competitor {
                    CardRow(card: competitor)
                } else {
                    Button(action: {
                        selectedSlotType = .competitor
                        showingCardPicker = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Set Competitor")
                        }
                    }
                }
            }

            // Main Deck (30 cards)
            Section("Main Deck (\(viewModel.mainDeckCards.count)/30)") {
                ForEach(1...30, id: \.self) { slotNum in
                    if let cardDetails = viewModel.mainDeckCards.first(where: { $0.slotNumber == slotNum }) {
                        HStack {
                            Text("\(slotNum).")
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)
                            CardRow(card: cardDetails.card)
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.removeCard(from: deck.id, slotType: .deck, slotNumber: slotNum)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    } else {
                        Button(action: {
                            selectedSlotType = .deck
                            selectedSlotNumber = slotNum
                            showingCardPicker = true
                        }) {
                            HStack {
                                Text("\(slotNum).")
                                    .foregroundColor(.secondary)
                                    .frame(width: 30, alignment: .leading)
                                Text("Empty Slot")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            // Finishes
            Section("Finishes (\(viewModel.finishCards.count))") {
                ForEach(viewModel.finishCards) { cardDetails in
                    CardRow(card: cardDetails.card)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.removeCard(from: deck.id, slotType: .finish, slotNumber: cardDetails.slotNumber)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                Button(action: {
                    selectedSlotType = .finish
                    showingCardPicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Finish")
                    }
                }
            }

            // Alternates
            Section("Alternates (\(viewModel.alternateCards.count))") {
                ForEach(viewModel.alternateCards) { cardDetails in
                    CardRow(card: cardDetails.card)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.removeCard(from: deck.id, slotType: .alternate, slotNumber: cardDetails.slotNumber)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                Button(action: {
                    selectedSlotType = .alternate
                    showingCardPicker = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add Alternate")
                    }
                }
            }
        }
        .navigationTitle(deck.name)
        .task {
            viewModel.selectedDeck = deck
            await viewModel.loadDeckCards(deck.id)
        }
        .sheet(isPresented: $showingCardPicker) {
            AddCardToDeckSheet(
                deckId: deck.id,
                folderId: deck.folderId,
                slotType: selectedSlotType,
                slotNumber: selectedSlotNumber
            )
        }
    }
}

// MARK: - Add Card to Deck Sheet

struct AddCardToDeckSheet: View {
    let deckId: String
    let folderId: String
    let slotType: DeckSlotType
    let slotNumber: Int

    @EnvironmentObject var viewModel: DeckViewModel
    @Environment(\.dismiss) var dismiss

    @State private var searchQuery = ""
    @State private var searchResults: [Card] = []
    @State private var isSearching = false
    @State private var availableCards: [Card] = []

    var body: some View {
        NavigationStack {
            Group {
                let cardsToShow = searchQuery.isEmpty ? availableCards : searchResults

                if isSearching {
                    ProgressView("Loading cards...")
                } else if cardsToShow.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(searchQuery.isEmpty ? "No cards available" : "No cards found")
                            .font(.headline)
                    }
                } else {
                    List(cardsToShow) { card in
                        Button(action: {
                            Task {
                                switch slotType {
                                case .entrance:
                                    await viewModel.setEntrance(card, in: deckId)
                                case .competitor:
                                    await viewModel.setCompetitor(card, in: deckId)
                                case .deck:
                                    await viewModel.setDeckCard(card, in: deckId, slotNumber: slotNumber)
                                case .finish:
                                    await viewModel.addFinish(card, to: deckId)
                                case .alternate:
                                    await viewModel.addAlternate(card, to: deckId)
                                }
                                dismiss()
                            }
                        }) {
                            CardRow(card: card)
                        }
                    }
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchQuery, prompt: "Search cards...")
            .onChange(of: searchQuery) { newValue in
                performSearch(newValue)
            }
            .task {
                await loadAvailableCards()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func loadAvailableCards() async {
        isSearching = true
        do {
            let dbService = viewModel.databaseService

            // Filter cards based on slot type and folder (matching Android logic)
            switch slotType {
            case .entrance:
                // Only EntranceCard type
                availableCards = try await dbService.searchCards(
                    query: nil,
                    cardType: "EntranceCard",
                    atkType: nil,
                    playOrder: nil,
                    division: nil,
                    releaseSet: nil,
                    isBanned: nil,
                    limit: 1000
                )

            case .competitor:
                // Depends on folder
                let cardType: String
                switch folderId {
                case "singles":
                    cardType = "SingleCompetitorCard"
                case "tornado":
                    cardType = "TornadoCompetitorCard"
                case "trios":
                    cardType = "TrioCompetitorCard"
                default:
                    // Tag or custom folders - load all competitor types
                    let singles = try await dbService.searchCards(query: nil, cardType: "SingleCompetitorCard", atkType: nil, playOrder: nil, division: nil, releaseSet: nil, isBanned: nil, limit: 1000)
                    let tornado = try await dbService.searchCards(query: nil, cardType: "TornadoCompetitorCard", atkType: nil, playOrder: nil, division: nil, releaseSet: nil, isBanned: nil, limit: 1000)
                    let trios = try await dbService.searchCards(query: nil, cardType: "TrioCompetitorCard", atkType: nil, playOrder: nil, division: nil, releaseSet: nil, isBanned: nil, limit: 1000)
                    availableCards = (singles + tornado + trios).sorted { $0.name < $1.name }
                    isSearching = false
                    return
                }
                availableCards = try await dbService.searchCards(
                    query: nil,
                    cardType: cardType,
                    atkType: nil,
                    playOrder: nil,
                    division: nil,
                    releaseSet: nil,
                    isBanned: nil,
                    limit: 1000
                )

            case .deck:
                // Only MainDeckCard type with matching deck_card_number
                let allMainDeck = try await dbService.searchCards(
                    query: nil,
                    cardType: "MainDeckCard",
                    atkType: nil,
                    playOrder: nil,
                    division: nil,
                    releaseSet: nil,
                    isBanned: nil,
                    limit: 1000
                )
                availableCards = allMainDeck.filter { $0.deckCardNumber == slotNumber }

            case .finish:
                // Only MainDeckCard type for finishes
                availableCards = try await dbService.searchCards(
                    query: nil,
                    cardType: "MainDeckCard",
                    atkType: nil,
                    playOrder: nil,
                    division: nil,
                    releaseSet: nil,
                    isBanned: nil,
                    limit: 1000
                )

            case .alternate:
                // Any card type
                availableCards = try await dbService.searchCards(
                    query: nil,
                    cardType: nil,
                    atkType: nil,
                    playOrder: nil,
                    division: nil,
                    releaseSet: nil,
                    isBanned: nil,
                    limit: 1000
                )
            }

        } catch {
            print("Error loading available cards: \(error)")
            availableCards = []
        }
        isSearching = false
    }

    private func performSearch(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        // Search within available cards
        searchResults = availableCards.filter { card in
            card.name.localizedCaseInsensitiveContains(query)
        }
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
