//
//  ImageHelper.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 11/25/25.
//

import Foundation
import SwiftUI

/// Helper for loading card images from local storage or server
struct ImageHelper {

    /// Get the URL for a card image
    /// Priority: Synced images directory → Documents directory → Server fallback
    static func imageURL(for cardId: String) -> URL? {
        let first2 = String(cardId.prefix(2))
        let imagePath = "images/mobile/\(first2)/\(cardId).webp"
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        // 1. Check synced images directory (from ImageSyncService)
        let syncedURL = documentsURL
            .appendingPathComponent("synced_images")
            .appendingPathComponent(first2)
            .appendingPathComponent("\(cardId).webp")

        if fileManager.fileExists(atPath: syncedURL.path) {
            return syncedURL
        }

        // 2. Check old Documents directory (legacy support)
        let localURL = documentsURL.appendingPathComponent(imagePath)

        if fileManager.fileExists(atPath: localURL.path) {
            return localURL
        }

        // 3. Fallback to server
        return URL(string: "https://get-diced.com/\(imagePath)")
    }

    /// Copy images from source directory to app Documents
    /// Call this once to set up local images
    static func copyImagesToDocuments(from sourceDirectory: URL) async throws {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let targetURL = documentsURL.appendingPathComponent("images/mobile")

        // Create target directory if needed
        try fileManager.createDirectory(at: targetURL, withIntermediateDirectories: true)

        // Get source mobile directory
        let sourceMobileURL = sourceDirectory.appendingPathComponent("mobile")

        // Copy all subdirectories (00, 01, 02, etc.)
        let subdirs = try fileManager.contentsOfDirectory(
            at: sourceMobileURL,
            includingPropertiesForKeys: nil
        )

        for subdir in subdirs where subdir.hasDirectoryPath {
            let subdirName = subdir.lastPathComponent
            let targetSubdir = targetURL.appendingPathComponent(subdirName)

            // Create subdirectory
            try fileManager.createDirectory(at: targetSubdir, withIntermediateDirectories: true)

            // Copy all webp files
            let imageFiles = try fileManager.contentsOfDirectory(
                at: subdir,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "webp" }

            for imageFile in imageFiles {
                let targetFile = targetSubdir.appendingPathComponent(imageFile.lastPathComponent)

                // Skip if already exists
                if !fileManager.fileExists(atPath: targetFile.path) {
                    try fileManager.copyItem(at: imageFile, to: targetFile)
                }
            }

            print("✅ Copied images for directory: \(subdirName)")
        }

        print("✅ All images copied to Documents")
    }

    /// Get the Documents directory path (for debugging)
    static func documentsPath() -> String {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.path
    }
}
