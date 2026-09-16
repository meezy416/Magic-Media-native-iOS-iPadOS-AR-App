//
//  Trigger.swift
//  MagicKettle
//

import Foundation

enum TriggerContentType: String, Codable {
    case video
    case audio
    case model
}

enum TriggerStatus: String, Codable {
    case pending
    case approved
    case rejected
}

/// Mirrors a row in the `public.triggers` table.
struct Trigger: Codable, Identifiable {
    let id: UUID
    let ownerId: UUID
    let title: String
    let targetImagePath: String
    let physicalWidthMeters: Float
    let contentType: TriggerContentType
    let contentPath: String
    let status: TriggerStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case title
        case targetImagePath = "target_image_path"
        case physicalWidthMeters = "physical_width_meters"
        case contentType = "content_type"
        case contentPath = "content_path"
        case status
        case createdAt = "created_at"
    }
}

/// Mirrors an insert into `public.triggers` (id/status/created_at are server-assigned).
struct NewTrigger: Codable {
    let ownerId: UUID
    let title: String
    let targetImagePath: String
    let physicalWidthMeters: Float
    let contentType: TriggerContentType
    let contentPath: String

    enum CodingKeys: String, CodingKey {
        case ownerId = "owner_id"
        case title
        case targetImagePath = "target_image_path"
        case physicalWidthMeters = "physical_width_meters"
        case contentType = "content_type"
        case contentPath = "content_path"
    }
}

/// Mirrors an insert into `public.reports`.
struct NewReport: Codable {
    let triggerId: UUID
    let reporterId: UUID
    let reason: String

    enum CodingKeys: String, CodingKey {
        case triggerId = "trigger_id"
        case reporterId = "reporter_id"
        case reason
    }
}
