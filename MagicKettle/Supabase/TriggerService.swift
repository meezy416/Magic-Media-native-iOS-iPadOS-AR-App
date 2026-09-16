//
//  TriggerService.swift
//  MagicKettle
//

import Foundation
import ARKit
import UIKit
import Supabase

/// Downloads community-uploaded triggers from Supabase and turns them into
/// runtime-built ARReferenceImages, so new AR triggers can appear without an app update.
final class TriggerService {

    static let shared = TriggerService()

    private let targetsBucket = "trigger-targets"
    private let contentBucket = "trigger-content"

    /// ARReferenceImage.name (== Trigger.id.uuidString) -> Trigger, so the renderer
    /// can resolve which cached content file to play for a tracked anchor.
    private(set) var triggersByReferenceName: [String: Trigger] = [:]

    private var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TriggerCache", isDirectory: true)
    }

    /// Fetches every approved trigger, downloads (or reuses cached) target images and
    /// content, and returns ARReferenceImages ready to merge into an AR configuration.
    func fetchApprovedTriggers() async throws -> [ARReferenceImage] {
        let client = SupabaseManager.shared.client

        let triggers: [Trigger] = try await client
            .from("triggers")
            .select()
            .eq("status", value: TriggerStatus.approved.rawValue)
            .execute()
            .value

        try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        var referenceImages: [ARReferenceImage] = []

        for trigger in triggers {
            do {
                let targetImageURL = try await cachedFileURL(bucket: targetsBucket, path: trigger.targetImagePath, client: client)
                _ = try await cachedFileURL(bucket: contentBucket, path: trigger.contentPath, client: client)

                guard
                    let imageData = try? Data(contentsOf: targetImageURL),
                    let uiImage = UIImage(data: imageData),
                    let cgImage = uiImage.cgImage
                else {
                    print("TriggerService: could not decode target image for trigger \(trigger.id)")
                    continue
                }

                let referenceImage = ARReferenceImage(
                    cgImage,
                    orientation: .up,
                    physicalWidth: CGFloat(trigger.physicalWidthMeters)
                )
                referenceImage.name = trigger.id.uuidString
                referenceImages.append(referenceImage)

                triggersByReferenceName[trigger.id.uuidString] = trigger
            } catch {
                print("TriggerService: failed to load trigger \(trigger.id): \(error)")
                continue
            }
        }

        return referenceImages
    }

    /// The local cache location for a trigger's content file, matching what
    /// fetchApprovedTriggers() already downloaded.
    func cachedContentURL(for trigger: Trigger) -> URL {
        cacheDirectory.appendingPathComponent(trigger.contentPath)
    }

    private func cachedFileURL(bucket: String, path: String, client: SupabaseClient) async throws -> URL {
        let destination = cacheDirectory.appendingPathComponent(path)

        if FileManager.default.fileExists(atPath: destination.path) {
            return destination
        }

        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let signedURL = try await client.storage.from(bucket).createSignedURL(path: path, expiresIn: 3600)
        let (tempURL, _) = try await URLSession.shared.download(from: signedURL)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)

        return destination
    }
}
