//
//  DatabaseSchema.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//
//  NOTE: 需要在Xcode中添加SQLite.swift SPM依赖
//  URL: https://github.com/stephencelis/SQLite.swift

import Foundation
import SQLite

/// 数据库表结构定义
enum DatabaseSchema {
    // MARK: - Stickers Table
    static let stickers = Table("stickers")

    struct StickersColumns {
        static let id = Expression<String>("id")
        static let filename = Expression<String>("filename")
        static let filePath = Expression<String>("file_path")
        static let fileSize = Expression<Int>("file_size")
        static let width = Expression<Int>("width")
        static let height = Expression<Int>("height")
        static let format = Expression<String>("format")
        static let createdAt = Expression<Int>("created_at")
        static let modifiedAt = Expression<Int>("modified_at")
        static let isPinned = Expression<Int>("is_pinned")
        static let isFavorite = Expression<Int>("is_favorite")
        static let usageCount = Expression<Int>("usage_count")
    }

    // MARK: - Tags Table
    static let tags = Table("tags")

    struct TagsColumns {
        static let id = Expression<Int>("id")
        static let name = Expression<String>("name")
        static let usageCount = Expression<Int>("usage_count")
        static let createdAt = Expression<Int>("created_at")
    }

    // MARK: - StickerTags Table
    static let stickerTags = Table("sticker_tags")

    struct StickerTagsColumns {
        static let stickerId = Expression<String>("sticker_id")
        static let tagId = Expression<Int>("tag_id")
        static let createdAt = Expression<Int>("created_at")
    }

    // MARK: - Table Creation
    /// 创建所有表
    static func createTables(in db: Connection) throws {
        // 创建stickers表
        try db.run(stickers.create(ifNotExists: true) { t in
            t.column(StickersColumns.id, primaryKey: true)
            t.column(StickersColumns.filename)
            t.column(StickersColumns.filePath)
            t.column(StickersColumns.fileSize)
            t.column(StickersColumns.width)
            t.column(StickersColumns.height)
            t.column(StickersColumns.format)
            t.column(StickersColumns.createdAt)
            t.column(StickersColumns.modifiedAt)
            t.column(StickersColumns.isPinned, defaultValue: 0)
            t.column(StickersColumns.isFavorite, defaultValue: 0)
            t.column(StickersColumns.usageCount, defaultValue: 0)
        })

        // 创建索引
        try db.run(stickers.createIndex(StickersColumns.createdAt, ifNotExists: true))
        try db.run(stickers.createIndex(StickersColumns.isPinned, ifNotExists: true))

        // 创建tags表
        try db.run(tags.create(ifNotExists: true) { t in
            t.column(TagsColumns.id, primaryKey: .autoincrement)
            t.column(TagsColumns.name, unique: true)
            t.column(TagsColumns.usageCount, defaultValue: 0)
            t.column(TagsColumns.createdAt)
        })

        // 创建索引
        try db.run(tags.createIndex(TagsColumns.name, ifNotExists: true))
        try db.run(tags.createIndex(TagsColumns.usageCount, ifNotExists: true))

        // 创建sticker_tags关联表
        try db.run(stickerTags.create(ifNotExists: true) { t in
            t.column(StickerTagsColumns.stickerId)
            t.column(StickerTagsColumns.tagId)
            t.column(StickerTagsColumns.createdAt)
            t.primaryKey(StickerTagsColumns.stickerId, StickerTagsColumns.tagId)
            t.foreignKey(StickerTagsColumns.stickerId, references: stickers, StickersColumns.id, delete: .cascade)
            t.foreignKey(StickerTagsColumns.tagId, references: tags, TagsColumns.id, delete: .cascade)
        })

        // 创建索引
        try db.run(stickerTags.createIndex(StickerTagsColumns.stickerId, ifNotExists: true))
        try db.run(stickerTags.createIndex(StickerTagsColumns.tagId, ifNotExists: true))
    }
}
