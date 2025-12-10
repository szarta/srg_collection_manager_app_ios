//
//  ImageSyncService.swift
//  GetDiced
//
//  Created by Brandon Arrendondo on 12/9/25.
//

import Foundation
import CryptoKit

/// Service for syncing card images using hash-based manifest
@MainActor
class ImageSyncService {

    private let apiClient = APIClient()
    private let fileManager = FileManager.default

    private static let IMAGES_DIR = "synced_images"
    private static let LOCAL_MANIFEST_FILE = "local_manifest.json"

    // MARK: - Directories

    /// Get the directory where synced images are stored
    private func getSyncedImagesDir() -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesURL = documentsURL.appendingPathComponent(Self.IMAGES_DIR)

        // Create directory if needed
        try? fileManager.createDirectory(at: imagesURL, withIntermediateDirectories: true)

        return imagesURL
    }

    /// Check if we have a synced version of an image
    func getSyncedImageFile(uuid: String) -> URL? {
        let first2 = String(uuid.prefix(2))
        let imageURL = getSyncedImagesDir()
            .appendingPathComponent(first2)
            .appendingPathComponent("\(uuid).webp")

        return fileManager.fileExists(atPath: imageURL.path) ? imageURL : nil
    }

    // MARK: - Manifest Loading

    /// Load the bundled manifest from app bundle
    private func loadBundledManifest() -> ImageManifest? {
        guard let manifestURL = Bundle.main.url(forResource: "images_manifest", withExtension: "json") else {
            print("❌ Bundled manifest not found in app bundle")
            return nil
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(ImageManifest.self, from: data)
            print("✅ Loaded bundled manifest: \(manifest.imageCount) images")
            return manifest
        } catch {
            print("❌ Error loading bundled manifest: \(error)")
            return nil
        }
    }

    /// Load the local manifest (for synced images)
    private func loadLocalManifest() -> ImageManifest? {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let manifestURL = documentsURL.appendingPathComponent(Self.LOCAL_MANIFEST_FILE)

        guard fileManager.fileExists(atPath: manifestURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(ImageManifest.self, from: data)
            print("✅ Loaded local manifest: \(manifest.imageCount) images")
            return manifest
        } catch {
            print("❌ Error loading local manifest: \(error)")
            return nil
        }
    }

    /// Save the local manifest after sync
    private func saveLocalManifest(_ manifest: ImageManifest) throws {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let manifestURL = documentsURL.appendingPathComponent(Self.LOCAL_MANIFEST_FILE)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)

        try data.write(to: manifestURL)
        print("✅ Saved local manifest: \(manifest.imageCount) images")
    }

    /// Get combined local hashes (bundled + synced)
    private func getLocalHashes() -> [String: String] {
        var hashes: [String: String] = [:]

        // Start with bundled manifest
        if let bundled = loadBundledManifest() {
            for (uuid, info) in bundled.images {
                hashes[uuid] = info.hash
            }
        }

        // Override with synced manifest (newer versions)
        if let local = loadLocalManifest() {
            for (uuid, info) in local.images {
                hashes[uuid] = info.hash
            }
        }

        return hashes
    }

    // MARK: - Image Syncing

    /// Sync images from server
    /// Returns: (downloaded count, total to sync)
    func syncImages(onProgress: @escaping (Int, Int) -> Void = { _, _ in }) async throws -> (Int, Int) {
        print("🔄 Starting image sync...")

        // Fetch server manifest from API
        let serverManifest = try await fetchServerManifest()
        print("📡 Server manifest: \(serverManifest.imageCount) images")

        // Get local hashes
        let localHashes = getLocalHashes()
        print("💾 Local hashes: \(localHashes.count) images")

        // Find images that need syncing (missing or different hash)
        let toSync = serverManifest.images.filter { uuid, serverInfo in
            let localHash = localHashes[uuid]
            return localHash == nil || localHash != serverInfo.hash
        }

        print("📥 Images to sync: \(toSync.count)")

        guard !toSync.isEmpty else {
            return (0, 0)
        }

        // Download images
        var downloaded = 0
        var syncedImages: [String: ImageInfo] = [:]

        for (uuid, serverInfo) in toSync {
            do {
                try await downloadImage(uuid: uuid, path: serverInfo.path)
                syncedImages[uuid] = serverInfo
                downloaded += 1
                onProgress(downloaded, toSync.count)
            } catch {
                print("❌ Failed to download image \(uuid): \(error)")
            }
        }

        // Update local manifest with synced images
        if !syncedImages.isEmpty {
            let existingLocal = loadLocalManifest()
            let updatedImages = (existingLocal?.images ?? [:]).merging(syncedImages) { _, new in new }

            let updatedManifest = ImageManifest(
                version: serverManifest.version,
                generated: serverManifest.generated,
                imageCount: updatedImages.count,
                images: updatedImages
            )

            try saveLocalManifest(updatedManifest)
        }

        print("✅ Image sync complete. Downloaded: \(downloaded)/\(toSync.count)")
        return (downloaded, toSync.count)
    }

    /// Download a single image from server
    private func downloadImage(uuid: String, path: String) async throws {
        let urlString = "https://get-diced.com/images/mobile/\(path)"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Save to synced images directory
        let first2 = String(uuid.prefix(2))
        let dirURL = getSyncedImagesDir().appendingPathComponent(first2)
        try fileManager.createDirectory(at: dirURL, withIntermediateDirectories: true)

        let fileURL = dirURL.appendingPathComponent("\(uuid).webp")
        try data.write(to: fileURL)
    }

    /// Fetch server manifest from API
    private func fetchServerManifest() async throws -> ImageManifest {
        let urlString = "https://get-diced.com/api/images/manifest"
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(ImageManifest.self, from: data)
    }

    // MARK: - Sync Status

    /// Get sync status: how many images need syncing
    func getSyncStatus() async throws -> (needSync: Int, total: Int) {
        let serverManifest = try await fetchServerManifest()
        let localHashes = getLocalHashes()

        let needSync = serverManifest.images.filter { uuid, serverInfo in
            let localHash = localHashes[uuid]
            return localHash == nil || localHash != serverInfo.hash
        }.count

        return (needSync, serverManifest.imageCount)
    }

    // MARK: - Verification

    /// Verify an image file's hash matches manifest
    func verifyImageHash(uuid: String, fileURL: URL) -> Bool {
        guard let imageInfo = loadBundledManifest()?.images[uuid] ?? loadLocalManifest()?.images[uuid] else {
            return false
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let hash = SHA256.hash(data: data)
            let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()

            return hashString == imageInfo.hash
        } catch {
            return false
        }
    }
}
