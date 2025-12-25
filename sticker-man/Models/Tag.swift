//
//  Tag.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import Foundation

/// 标签数据模型
struct Tag: Identifiable, Codable {
    let id: Int
    var name: String
    var usageCount: Int
    var createdAt: Int

    init(
        id: Int = 0,
        name: String,
        usageCount: Int = 0,
        createdAt: Int = Date().unixTimestamp
    ) {
        self.id = id
        self.name = name
        self.usageCount = usageCount
        self.createdAt = createdAt
    }
}

// MARK: - Equatable
extension Tag: Equatable {
    static func == (lhs: Tag, rhs: Tag) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension Tag: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
