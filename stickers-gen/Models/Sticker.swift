//
//  Sticker.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import Foundation

/// 表情包数据模型
struct Sticker: Identifiable, Codable {
    let id: String
    var filename: String
    var filePath: String
    var fileSize: Int
    var width: Int
    var height: Int
    var format: String
    var createdAt: Int
    var modifiedAt: Int
    var isPinned: Bool
    var isFavorite: Bool
    var usageCount: Int
    var tags: [String]  // 关联的标签名称列表

    init(
        id: String = String.generateUUID(),
        filename: String,
        filePath: String,
        fileSize: Int,
        width: Int,
        height: Int,
        format: String,
        createdAt: Int = Date().unixTimestamp,
        modifiedAt: Int = Date().unixTimestamp,
        isPinned: Bool = false,
        isFavorite: Bool = false,
        usageCount: Int = 0,
        tags: [String] = []
    ) {
        self.id = id
        self.filename = filename
        self.filePath = filePath
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.format = format
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.isPinned = isPinned
        self.isFavorite = isFavorite
        self.usageCount = usageCount
        self.tags = tags
    }

    /// 获取完整文件URL
    var fullURL: URL {
        return URL.stickersDirectory.appendingPathComponent(filePath)
    }

    /// 获取缩略图URL
    var thumbnailURL: URL {
        let thumbnailFilename = id + "_thumb.jpg"
        return URL.thumbnailsDirectory.appendingPathComponent(thumbnailFilename)
    }
}

// MARK: - Equatable
extension Sticker: Equatable {
    static func == (lhs: Sticker, rhs: Sticker) -> Bool {
        return lhs.id == rhs.id &&
               lhs.filename == rhs.filename &&
               lhs.isPinned == rhs.isPinned &&
               lhs.isFavorite == rhs.isFavorite &&
               lhs.tags == rhs.tags &&
               lhs.modifiedAt == rhs.modifiedAt
    }
}

// MARK: - Hashable
extension Sticker: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
