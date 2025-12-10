//
//  CSVHelper.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 12/8/24.
//

import Foundation

/// Helper for CSV export and import operations
class CSVHelper {

    // MARK: - Deck CSV

    /// Export deck to CSV format
    /// Format: Slot Type,Slot Number,Card Name
    static func exportDeck(deckName: String, cards: [DeckCardWithDetails]) -> String {
        var csv = "Slot Type,Slot Number,Card Name\n"

        // Sort cards by slot type and number
        let sortedCards = cards.sorted { lhs, rhs in
            let lhsPriority = slotTypePriority(lhs.slotType)
            let rhsPriority = slotTypePriority(rhs.slotType)

            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }
            return lhs.slotNumber < rhs.slotNumber
        }

        for cardDetails in sortedCards {
            let slotType = cardDetails.slotType.rawValue
            let slotNumber = cardDetails.slotNumber
            let cardName = escapeCSVField(cardDetails.card.name)
            csv += "\(slotType),\(slotNumber),\"\(cardName)\"\n"
        }

        return csv
    }

    /// Parse deck CSV data
    /// Returns: Array of (slotType, slotNumber, cardName)
    static func parseDeckCSV(_ csvString: String) -> [(slotType: String, slotNumber: Int, cardName: String)]? {
        var result: [(String, Int, String)] = []

        let lines = csvString.components(separatedBy: .newlines)

        // Skip header
        for (index, line) in lines.enumerated() {
            if index == 0 || line.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }

            let fields = parseCSVLine(line)
            guard fields.count >= 3 else { continue }

            let slotType = fields[0]
            guard let slotNumber = Int(fields[1]) else { continue }
            let cardName = fields[2]

            result.append((slotType, slotNumber, cardName))
        }

        return result.isEmpty ? nil : result
    }

    // MARK: - Collection CSV

    /// Export collection to CSV format
    /// Format: Name,Quantity,Card Type,Deck #,Attack Type,Play Order,Division
    static func exportCollection(folderName: String, cards: [(card: Card, quantity: Int)]) -> String {
        var csv = "Name,Quantity,Card Type,Deck #,Attack Type,Play Order,Division\n"

        for item in cards {
            let card = item.card
            let name = escapeCSVField(card.name)
            let quantity = item.quantity
            let cardType = card.cardType.replacingOccurrences(of: "Card", with: "")
            let deckNum = card.deckCardNumber?.description ?? ""
            let atkType = card.atkType ?? ""
            let playOrder = card.playOrder ?? ""
            let division = card.division ?? ""

            csv += "\"\(name)\",\(quantity),\(cardType),\(deckNum),\(atkType),\(playOrder),\(division)\n"
        }

        return csv
    }

    /// Parse collection CSV data
    /// Returns: Array of (cardName, quantity)
    static func parseCollectionCSV(_ csvString: String) -> [(cardName: String, quantity: Int)]? {
        var result: [(String, Int)] = []

        let lines = csvString.components(separatedBy: .newlines)

        // Skip header
        for (index, line) in lines.enumerated() {
            if index == 0 || line.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }

            let fields = parseCSVLine(line)
            guard fields.count >= 2 else { continue }

            let cardName = fields[0]
            guard let quantity = Int(fields[1]) else { continue }

            result.append((cardName, quantity))
        }

        return result.isEmpty ? nil : result
    }

    // MARK: - Helper Methods

    private static func slotTypePriority(_ slotType: DeckSlotType) -> Int {
        switch slotType {
        case .entrance: return 0
        case .competitor: return 1
        case .deck: return 2
        case .finish: return 3
        case .alternate: return 4
        }
    }

    private static func escapeCSVField(_ field: String) -> String {
        // Escape quotes by doubling them
        return field.replacingOccurrences(of: "\"", with: "\"\"")
    }

    /// Parse a single CSV line with support for quoted fields
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            } else {
                currentField.append(char)
            }
        }

        // Add last field
        fields.append(currentField.trimmingCharacters(in: .whitespaces))

        return fields
    }
}
