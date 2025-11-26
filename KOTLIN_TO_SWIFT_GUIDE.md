# Kotlin to Swift Translation Guide

Quick reference for translating Android Kotlin code to iOS Swift for the Get Diced app.

## Side-by-Side Examples

### Card Model Comparison

**Android (Kotlin):**
```kotlin
@Entity(tableName = "cards")
data class Card(
    @PrimaryKey
    @ColumnInfo(name = "db_uuid")
    val dbUuid: String,

    @ColumnInfo(name = "name")
    val name: String,

    @ColumnInfo(name = "card_type")
    val cardType: String,

    @ColumnInfo(name = "is_banned")
    val isBanned: Boolean = false,

    @ColumnInfo(name = "synced_at")
    val syncedAt: Long = System.currentTimeMillis()
) {
    val isCompetitor: Boolean
        get() = cardType.contains("Competitor")
}
```

**iOS (Swift):**
```swift
struct Card: Identifiable, Codable {
    let id: String
    let name: String
    let cardType: String
    let isBanned: Bool
    let syncedAt: Int64

    enum CodingKeys: String, CodingKey {
        case id = "db_uuid"
        case name
        case cardType = "card_type"
        case isBanned = "is_banned"
        case syncedAt = "synced_at"
    }

    var isCompetitor: Bool {
        cardType.contains("Competitor")
    }
}
```

### Enum Comparison

**Android (Kotlin):**
```kotlin
enum class SpectacleType {
    NEWMAN,
    VALIANT
}
```

**iOS (Swift):**
```swift
enum SpectacleType: String, Codable {
    case newman = "NEWMAN"
    case valiant = "VALIANT"
}
```

### Junction Table with Composite Key

**Android (Kotlin):**
```kotlin
@Entity(
    tableName = "folder_cards",
    primaryKeys = ["folder_id", "card_uuid"]
)
data class FolderCard(
    @ColumnInfo(name = "folder_id")
    val folderId: String,

    @ColumnInfo(name = "card_uuid")
    val cardUuid: String,

    @ColumnInfo(name = "quantity")
    val quantity: Int = 1
)
```

**iOS (Swift):**
```swift
struct FolderCard: Codable, Hashable {
    let folderId: String
    let cardUuid: String
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case folderId = "folder_id"
        case cardUuid = "card_uuid"
        case quantity
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(folderId)
        hasher.combine(cardUuid)
    }

    static func == (lhs: FolderCard, rhs: FolderCard) -> Bool {
        lhs.folderId == rhs.folderId && lhs.cardUuid == rhs.cardUuid
    }
}
```

## Key Patterns

### 1. Data Classes → Structs

| Kotlin | Swift |
|--------|-------|
| `data class Foo(...)` | `struct Foo { ... }` |
| Auto-generates: equals, hashCode, toString, copy | Must implement manually if needed |
| Reference type | Value type (copied on assignment) |

### 2. Properties

| Kotlin | Swift | Notes |
|--------|-------|-------|
| `val x: String` | `let x: String` | Immutable |
| `var x: String` | `var x: String` | Mutable |
| `val x: String?` | `let x: String?` | Optional |
| `val x: String = "default"` | `let x: String = "default"` | Default value |

### 3. Computed Properties

| Kotlin | Swift |
|--------|-------|
| `val computed: Int get() = x + y` | `var computed: Int { x + y }` |
| Custom getter | Computed property |

### 4. Types

| Kotlin | Swift | Notes |
|--------|-------|-------|
| `String` | `String` | Same |
| `Int` | `Int` | 32/64-bit depending on platform |
| `Long` | `Int64` | Always 64-bit |
| `Boolean` | `Bool` | Same concept |
| `Double` | `Double` | Same |
| `List<T>` | `[T]` | Array in Swift |
| `Map<K,V>` | `[K: V]` | Dictionary in Swift |

### 5. Nullability

| Kotlin | Swift | Notes |
|--------|-------|-------|
| `String?` | `String?` | Optional |
| `String` | `String` | Non-optional |
| `x?.method()` | `x?.method()` | Optional chaining |
| `x ?: default` | `x ?? default` | Null coalescing |
| `x!!` | `x!` | Force unwrap (avoid!) |

### 6. Collections

**Kotlin:**
```kotlin
val tags: String? = null
val tagList: List<String>
    get() = tags?.split(",")?.map { it.trim() } ?: emptyList()
```

**Swift:**
```swift
let tags: String?
var tagList: [String] {
    tags?.split(separator: ",").map {
        $0.trimmingCharacters(in: .whitespaces)
    } ?? []
}
```

### 7. Initializers

**Kotlin (automatic):**
```kotlin
data class Folder(
    val id: String = UUID.randomUUID().toString(),
    val name: String,
    val isDefault: Boolean = false
)
```

**Swift (manual):**
```swift
struct Folder {
    let id: String
    let name: String
    let isDefault: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
    }
}
```

### 8. Timestamps

| Kotlin | Swift |
|--------|-------|
| `System.currentTimeMillis()` | `Int64(Date().timeIntervalSince1970 * 1000)` |
| Returns `Long` (milliseconds) | Returns `Int64` (milliseconds) |

### 9. JSON Serialization

**Kotlin (Gson):**
```kotlin
@SerializedName("card_type")
val cardType: String
```

**Swift (Codable):**
```swift
let cardType: String

enum CodingKeys: String, CodingKey {
    case cardType = "card_type"
}
```

### 10. Identifiable for Lists

**Kotlin (Jetpack Compose):**
```kotlin
@Composable
fun CardList(cards: List<Card>) {
    LazyColumn {
        items(cards) { card ->
            CardRow(card)
        }
    }
}
```

**Swift (SwiftUI):**
```swift
struct CardListView: View {
    let cards: [Card]

    var body: some View {
        List(cards) { card in  // Requires Identifiable
            CardRow(card: card)
        }
    }
}
```

## Database Layer

### Room (Android) → SQLite.swift (iOS)

**Android DAO:**
```kotlin
@Dao
interface CardDao {
    @Query("SELECT * FROM cards WHERE db_uuid = :uuid")
    suspend fun getCardById(uuid: String): Card?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCard(card: Card)

    @Query("SELECT * FROM cards WHERE name LIKE :query")
    fun searchCards(query: String): Flow<List<Card>>
}
```

**iOS Service (planned):**
```swift
class DatabaseService {
    func getCard(byId uuid: String) async throws -> Card? {
        // SQLite.swift implementation
    }

    func insertCard(_ card: Card) async throws {
        // SQLite.swift implementation
    }

    func searchCards(query: String) -> AsyncStream<[Card]> {
        // SQLite.swift implementation with async stream
    }
}
```

## API Layer

### Retrofit (Android) → URLSession (iOS)

**Android:**
```kotlin
interface GetDicedApi {
    @GET("cards")
    suspend fun searchCards(
        @Query("q") query: String?
    ): PaginatedCardResponse
}

// Usage
val response = api.searchCards(query = "John")
```

**iOS:**
```swift
class APIClient {
    func searchCards(query: String?) async throws -> PaginatedCardResponse {
        var components = URLComponents(string: "\(baseURL)/cards")!
        if let query = query {
            components.queryItems = [URLQueryItem(name: "q", value: query)]
        }

        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(PaginatedCardResponse.self, from: data)
    }
}

// Usage
let response = try await apiClient.searchCards(query: "John")
```

## State Management

### ViewModel Comparison

**Android (Kotlin + Flow):**
```kotlin
class CollectionViewModel : ViewModel() {
    private val _folders = MutableStateFlow<List<Folder>>(emptyList())
    val folders: StateFlow<List<Folder>> = _folders.asStateFlow()

    fun loadFolders() {
        viewModelScope.launch {
            repository.getAllFolders().collect { folderList ->
                _folders.value = folderList
            }
        }
    }
}
```

**iOS (Swift + Combine/ObservableObject):**
```swift
@MainActor
class CollectionViewModel: ObservableObject {
    @Published var folders: [Folder] = []

    func loadFolders() async {
        do {
            folders = try await repository.getAllFolders()
        } catch {
            print("Error loading folders: \(error)")
        }
    }
}
```

## Concurrency

| Kotlin | Swift |
|--------|-------|
| `suspend fun` | `async func` |
| `viewModelScope.launch { }` | `Task { }` |
| `Flow<T>` | `AsyncStream<T>` or `@Published` |
| `coroutineScope { }` | `async let` or `TaskGroup` |
| `Dispatchers.Main` | `@MainActor` |
| `Dispatchers.IO` | `Task { }` (no explicit dispatcher) |

## String Operations

| Kotlin | Swift |
|--------|-------|
| `"$name is $age"` | `"\(name) is \(age)"` |
| `str.contains("foo")` | `str.contains("foo")` |
| `str.split(",")` | `str.split(separator: ",")` |
| `str.trim()` | `str.trimmingCharacters(in: .whitespaces)` |
| `str.isEmpty()` | `str.isEmpty` |

## Key Differences to Remember

### 1. Value vs Reference Types
- **Kotlin**: Classes are reference types
- **Swift**: Structs are value types (copied), Classes are reference types

For data models, Swift uses `struct` (value type) while Kotlin uses `data class` (reference type).

### 2. Protocol Conformance
- **Kotlin**: Annotations (`@Entity`, `@Serializable`)
- **Swift**: Protocol conformance (`Codable`, `Identifiable`, `Hashable`)

### 3. No Automatic Implementations
- Kotlin `data class` auto-generates `equals()`, `hashCode()`, `toString()`, `copy()`
- Swift `struct` requires manual implementation of `Hashable`, `Equatable` if needed

### 4. Optionals are Explicit
- Both use `?` for optionals
- Swift is stricter about optional handling at compile time

### 5. No Kotlin Extension Functions (Out of Box)
- Kotlin: `fun String.toFoo() = Foo(this)`
- Swift: Use extensions, but syntax differs: `extension String { func toFoo() -> Foo { ... } }`

## Testing Translations

When porting code, verify:

1. ✅ Property types match (Long → Int64)
2. ✅ Optionality matches (String? → String?)
3. ✅ Default values match
4. ✅ Computed properties work the same
5. ✅ Enum raw values match database strings
6. ✅ CodingKeys match database column names
7. ✅ Composite keys use Hashable correctly

## Common Gotchas

### 1. Timestamps
```kotlin
// Kotlin - milliseconds
val now = System.currentTimeMillis()  // Long
```

```swift
// Swift - need to multiply by 1000
let now = Int64(Date().timeIntervalSince1970 * 1000)  // Int64
```

### 2. UUID Generation
```kotlin
UUID.randomUUID().toString()
```

```swift
UUID().uuidString  // Note: uuidString not toString()
```

### 3. Split and Map
```kotlin
tags?.split(",")?.map { it.trim() }
```

```swift
tags?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
```

### 4. List Iteration
```kotlin
items.forEach { item ->
    println(item.name)
}
```

```swift
items.forEach { item in
    print(item.name)
}
```

## Conclusion

Most patterns translate directly with minor syntax changes. The biggest differences are:
- Room → SQLite.swift (manual SQL)
- Retrofit → URLSession (manual networking)
- Flow → AsyncStream or @Published
- Coroutines → async/await (very similar!)

All data models are now ready in Swift! 🎉
