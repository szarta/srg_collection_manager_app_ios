//
//  CardSearchViewModel.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 11/26/24.
//

import Foundation
import Combine

@MainActor
class CardSearchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var cards: [Card] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Search & Filters
    @Published var searchQuery: String = ""
    @Published var selectedCardType: String?
    @Published var selectedAtkType: String?
    @Published var selectedPlayOrder: String?
    @Published var selectedDivision: String?
    @Published var selectedReleaseSet: String?
    @Published var showBannedOnly: Bool = false

    // Filter Options (loaded from database)
    @Published var availableCardTypes: [String] = []
    @Published var availableDivisions: [String] = []
    @Published var availableReleaseSets: [String] = []

    // MARK: - Dependencies

    let databaseService: DatabaseService
    private var searchTask: Task<Void, Never>?

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
            availableReleaseSets = try await databaseService.getAllReleaseSets()
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
        Publishers.CombineLatest4(
            $selectedCardType,
            $selectedDivision,
            $selectedAtkType,
            $selectedPlayOrder
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.searchTask?.cancel()
            self?.searchTask = Task {
                await self?.performSearch()
            }
        }
        .store(in: &cancellables)

        // Trigger search on banned filter change
        $showBannedOnly
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

    /// Perform search with current filters
    func performSearch() async {
        isLoading = true
        errorMessage = nil

        do {
            // If no filters applied, load all cards (up to limit)
            let query = searchQuery.isEmpty ? nil : searchQuery
            let bannedFilter = showBannedOnly ? true : nil

            cards = try await databaseService.searchCards(
                query: query,
                cardType: selectedCardType,
                atkType: selectedAtkType,
                playOrder: selectedPlayOrder,
                division: selectedDivision,
                releaseSet: selectedReleaseSet,
                isBanned: bannedFilter,
                limit: 200  // Show more cards in viewer
            )
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            cards = []
        }

        isLoading = false
    }

    /// Load initial cards (all cards, limited)
    func loadInitialCards() async {
        await performSearch()
    }

    // MARK: - Filter Management

    /// Clear all filters
    func clearFilters() {
        searchQuery = ""
        selectedCardType = nil
        selectedAtkType = nil
        selectedPlayOrder = nil
        selectedDivision = nil
        selectedReleaseSet = nil
        showBannedOnly = false
    }

    /// Check if any filters are active
    var hasActiveFilters: Bool {
        return !searchQuery.isEmpty ||
               selectedCardType != nil ||
               selectedAtkType != nil ||
               selectedPlayOrder != nil ||
               selectedDivision != nil ||
               selectedReleaseSet != nil ||
               showBannedOnly
    }
}
