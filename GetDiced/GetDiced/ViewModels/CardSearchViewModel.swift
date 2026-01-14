//
//  CardSearchViewModel.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 11/26/24.
//

import Foundation
import Combine

/// Search scope options (multi-select)
enum SearchScope: String, CaseIterable, Hashable {
    case name = "name"
    case rules = "rules"
    case tags = "tags"

    var displayName: String {
        switch self {
        case .name: return "Name"
        case .rules: return "Rules"
        case .tags: return "Tags"
        }
    }
}

@MainActor
class CardSearchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var cards: [Card] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingMore: Bool = false
    @Published var errorMessage: String?
    @Published var hasMoreResults: Bool = true

    // Search & Filters
    @Published var searchQuery: String = ""
    @Published var searchScopes: Set<SearchScope> = [.name, .tags, .rules] // Multi-select, all enabled by default
    @Published var selectedCardType: String?
    @Published var selectedDivision: String?
    @Published var selectedDeckCardNumbers: Set<Int> = [] // Multi-select deck card numbers (1-30)

    // Stat filters - minimum values (5-30, default 5)
    @Published var minPower: Int = 5
    @Published var minTechnique: Int = 5
    @Published var minAgility: Int = 5
    @Published var minStrike: Int = 5
    @Published var minSubmission: Int = 5
    @Published var minGrapple: Int = 5

    // Filter Options (loaded from database)
    @Published var availableCardTypes: [String] = []
    @Published var availableDivisions: [String] = []

    // MARK: - Dependencies

    let databaseService: DatabaseService
    private var searchTask: Task<Void, Never>?

    // MARK: - Pagination

    private var currentOffset: Int = 0
    private let pageSize: Int = 50

    // MARK: - Initialization

    init(databaseService: DatabaseService) {
        self.databaseService = databaseService
        setupSearchDebounce()
    }

    // MARK: - Setup

    /// Load filter options from database
    func loadFilterOptions() async {
        do {
            availableCardTypes = try await databaseService.getAllCardTypes()
            availableDivisions = try await databaseService.getAllDivisions()
        } catch {
            errorMessage = "Failed to load filters: \(error.localizedDescription)"
        }
    }

    // MARK: - Search Operations

    /// Setup search debounce to avoid rapid queries
    private func setupSearchDebounce() {
        // Debounce search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.searchTask?.cancel()
                self?.searchTask = Task {
                    await self?.performSearch()
                }
            }
            .store(in: &cancellables)

        // Also trigger search when filters change
        Publishers.CombineLatest(
            $selectedCardType,
            $selectedDivision
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.searchTask?.cancel()
            self?.searchTask = Task {
                await self?.performSearch()
            }
        }
        .store(in: &cancellables)

        Publishers.CombineLatest(
            $searchScopes,
            $selectedDeckCardNumbers
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.searchTask?.cancel()
            self?.searchTask = Task {
                await self?.performSearch()
            }
        }
        .store(in: &cancellables)

        // Trigger search on stat filter changes
        Publishers.CombineLatest(
            Publishers.CombineLatest3($minPower, $minTechnique, $minAgility),
            Publishers.CombineLatest3($minStrike, $minSubmission, $minGrapple)
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.searchTask?.cancel()
            self?.searchTask = Task {
                await self?.performSearch()
            }
        }
        .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    /// Perform search with current filters (resets pagination)
    func performSearch() async {
        isLoading = true
        errorMessage = nil
        currentOffset = 0
        hasMoreResults = true

        do {
            // If no filters applied, load all cards (up to limit)
            let query = searchQuery.isEmpty ? nil : searchQuery

            let results = try await databaseService.searchCards(
                query: query,
                searchScopes: searchScopes,
                cardType: selectedCardType,
                atkType: nil,
                playOrder: nil,
                division: selectedDivision,
                releaseSet: nil,
                isBanned: nil,
                deckCardNumbers: selectedDeckCardNumbers,
                minPower: minPower,
                minTechnique: minTechnique,
                minAgility: minAgility,
                minStrike: minStrike,
                minSubmission: minSubmission,
                minGrapple: minGrapple,
                limit: pageSize
            )

            cards = results
            currentOffset = pageSize
            hasMoreResults = results.count == pageSize
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            cards = []
            hasMoreResults = false
        }

        isLoading = false
    }

    /// Load next page of results (infinite scroll)
    func loadNextPage() async {
        guard !isLoadingMore && hasMoreResults else { return }

        isLoadingMore = true

        do {
            let query = searchQuery.isEmpty ? nil : searchQuery

            // Note: SQLite doesn't support offset directly, so we'll need to implement
            // pagination by filtering out already-loaded cards
            let results = try await databaseService.searchCards(
                query: query,
                searchScopes: searchScopes,
                cardType: selectedCardType,
                atkType: nil,
                playOrder: nil,
                division: selectedDivision,
                releaseSet: nil,
                isBanned: nil,
                deckCardNumbers: selectedDeckCardNumbers,
                minPower: minPower,
                minTechnique: minTechnique,
                minAgility: minAgility,
                minStrike: minStrike,
                minSubmission: minSubmission,
                minGrapple: minGrapple,
                limit: currentOffset + pageSize
            )

            // Get only the new cards
            let newCards = Array(results.dropFirst(currentOffset))
            cards.append(contentsOf: newCards)
            currentOffset += newCards.count
            hasMoreResults = newCards.count == pageSize
        } catch {
            errorMessage = "Failed to load more: \(error.localizedDescription)"
            hasMoreResults = false
        }

        isLoadingMore = false
    }

    /// Load initial cards (all cards, limited)
    func loadInitialCards() async {
        await performSearch()
    }

    // MARK: - Filter Management

    /// Clear all filters
    func clearFilters() {
        searchQuery = ""
        searchScopes = [.name, .tags, .rules] // Reset to all scopes
        selectedCardType = nil
        selectedDivision = nil
        selectedDeckCardNumbers = []
        minPower = 5
        minTechnique = 5
        minAgility = 5
        minStrike = 5
        minSubmission = 5
        minGrapple = 5
    }

    /// Check if any filters are active
    var hasActiveFilters: Bool {
        return !searchQuery.isEmpty ||
               searchScopes != [.name, .tags, .rules] ||
               selectedCardType != nil ||
               selectedDivision != nil ||
               !selectedDeckCardNumbers.isEmpty ||
               minPower > 5 ||
               minTechnique > 5 ||
               minAgility > 5 ||
               minStrike > 5 ||
               minSubmission > 5 ||
               minGrapple > 5
    }
}
