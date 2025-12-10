import Foundation

/// API client for get-diced.com API
@MainActor
class APIClient {

    // MARK: - Properties

    private let baseURL = "https://get-diced.com"
    private let session: URLSession
    private let decoder: JSONDecoder

    // MARK: - Initialization

    init() {
        // Configure URLSession with timeouts
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30  // 30 seconds
        configuration.timeoutIntervalForResource = 60 // 60 seconds

        self.session = URLSession(configuration: configuration)

        // Configure JSON decoder
        self.decoder = JSONDecoder()
        // Note: Our models use CodingKeys, so we use default key decoding
    }

    // MARK: - Card Endpoints

    /// Search cards with optional filters
    /// GET /cards?q={query}&card_type={type}&atk_type={atk}&...
    func searchCards(
        query: String? = nil,
        cardType: String? = nil,
        atkType: String? = nil,
        playOrder: String? = nil,
        division: String? = nil,
        gender: String? = nil,
        isBanned: Bool? = nil,
        releaseSet: String? = nil,
        limit: Int = 100,
        offset: Int = 0
    ) async throws -> PaginatedCardResponse {
        var components = URLComponents(string: "\(baseURL)/cards")!

        var queryItems: [URLQueryItem] = []
        if let query = query { queryItems.append(URLQueryItem(name: "q", value: query)) }
        if let cardType = cardType { queryItems.append(URLQueryItem(name: "card_type", value: cardType)) }
        if let atkType = atkType { queryItems.append(URLQueryItem(name: "atk_type", value: atkType)) }
        if let playOrder = playOrder { queryItems.append(URLQueryItem(name: "play_order", value: playOrder)) }
        if let division = division { queryItems.append(URLQueryItem(name: "division", value: division)) }
        if let gender = gender { queryItems.append(URLQueryItem(name: "gender", value: gender)) }
        if let isBanned = isBanned { queryItems.append(URLQueryItem(name: "is_banned", value: String(isBanned))) }
        if let releaseSet = releaseSet { queryItems.append(URLQueryItem(name: "release_set", value: releaseSet)) }
        queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        queryItems.append(URLQueryItem(name: "offset", value: String(offset)))

        components.queryItems = queryItems.isEmpty ? nil : queryItems

        let (data, response) = try await session.data(from: components.url!)
        try validateResponse(response)

        return try decoder.decode(PaginatedCardResponse.self, from: data)
    }

    /// Get single card by UUID
    /// GET /cards/{uuid}
    func getCard(byUuid uuid: String) async throws -> CardDTO {
        let url = URL(string: "\(baseURL)/cards/\(uuid)")!

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        return try decoder.decode(CardDTO.self, from: data)
    }

    /// Get single card by slug
    /// GET /cards/slug/{slug}
    func getCard(bySlug slug: String) async throws -> CardDTO {
        let url = URL(string: "\(baseURL)/cards/slug/\(slug)")!

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        return try decoder.decode(CardDTO.self, from: data)
    }

    /// Get multiple cards by UUIDs in batch
    /// POST /cards/by-uuids
    func getCards(byUuids uuids: [String]) async throws -> CardBatchResponse {
        let url = URL(string: "\(baseURL)/cards/by-uuids")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = CardBatchRequest(uuids: uuids)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        return try decoder.decode(CardBatchResponse.self, from: data)
    }

    // MARK: - Shared List Endpoints (Deck Sharing)

    /// Create a shared list (for deck or collection sharing)
    /// POST /api/shared-lists
    func createSharedList(
        name: String?,
        description: String?,
        cardUuids: [String],
        listType: String = "COLLECTION",
        deckData: DeckData? = nil
    ) async throws -> SharedListCreateResponse {
        let url = URL(string: "\(baseURL)/api/shared-lists")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = SharedListRequest(
            name: name,
            description: description,
            cardUuids: cardUuids,
            listType: listType,
            deckData: deckData
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(requestBody)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        return try decoder.decode(SharedListCreateResponse.self, from: data)
    }

    /// Get shared list by ID
    /// GET /api/shared-lists/{shared_id}
    func getSharedList(byId sharedId: String) async throws -> SharedListResponse {
        let url = URL(string: "\(baseURL)/api/shared-lists/\(sharedId)")!

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        return try decoder.decode(SharedListResponse.self, from: data)
    }

    /// Delete shared list by ID
    /// DELETE /api/shared-lists/{shared_id}
    func deleteSharedList(byId sharedId: String) async throws {
        let url = URL(string: "\(baseURL)/api/shared-lists/\(sharedId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Sync Endpoints

    /// Get cards database manifest (for checking if update needed)
    /// GET /api/cards/manifest
    func getCardsManifest() async throws -> CardsManifest {
        let url = URL(string: "\(baseURL)/api/cards/manifest")!

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        return try decoder.decode(CardsManifest.self, from: data)
    }

    /// Get images manifest (for checking which images need updating)
    /// GET /api/images/manifest
    func getImageManifest() async throws -> ImageManifest {
        let url = URL(string: "\(baseURL)/api/images/manifest")!

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        return try decoder.decode(ImageManifest.self, from: data)
    }

    /// Download cards database file
    /// GET /api/cards/database
    /// Returns: Raw Data for the .db file
    func downloadCardsDatabase(filename: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/api/cards/database")!

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        return data
    }

    /// Download image file
    /// GET /images/mobile/{path}
    /// Returns: Raw Data for the image file
    func downloadImage(path: String) async throws -> Data {
        let url = URL(string: "\(baseURL)/images/mobile/\(path)")!

        let (data, response) = try await session.data(from: url)
        try validateResponse(response)

        return data
    }

    // MARK: - Helper Methods

    /// Validate HTTP response
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 400:
            throw APIError.badRequest
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.unknownError(httpResponse.statusCode)
        }
    }
}

// MARK: - API Errors

enum APIError: Error, LocalizedError {
    case invalidResponse
    case badRequest
    case unauthorized
    case notFound
    case serverError(Int)
    case unknownError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .badRequest:
            return "Bad request (400)"
        case .unauthorized:
            return "Unauthorized (401)"
        case .notFound:
            return "Resource not found (404)"
        case .serverError(let code):
            return "Server error (\(code))"
        case .unknownError(let code):
            return "Unknown error (\(code))"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Usage Examples

/*
 Usage examples for when implementing in Xcode:

 // Search cards
 let results = try await apiClient.searchCards(
     query: "John Cena",
     cardType: "SingleCompetitorCard",
     limit: 50
 )

 // Get single card
 let card = try await apiClient.getCard(byUuid: "some-uuid-here")

 // Create shared list (deck sharing)
 let response = try await apiClient.createSharedList(
     name: "My Awesome Deck",
     description: "This is my deck",
     cardUuids: ["uuid1", "uuid2", "uuid3"]
 )
 print("Share URL: \(response.url)")

 // Check for database updates
 let manifest = try await apiClient.getCardsManifest()
 if manifest.version > currentDatabaseVersion {
     // Download and replace database
     let dbData = try await apiClient.downloadCardsDatabase(filename: manifest.filename)
     // Save to disk...
 }

 // Download image
 let imageData = try await apiClient.downloadImage(path: "ab/cd/uuid.webp")
 let image = UIImage(data: imageData)
 */
