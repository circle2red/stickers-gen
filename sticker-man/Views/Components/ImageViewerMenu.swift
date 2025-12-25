//
//  ImageViewerMenu.swift
//  stickers-gen
//
//  Created on 2025/12/26.
//

import Foundation

/// 图片查看器菜单操作类型
enum MenuAction: Equatable {
    case editTags
    case editImage
    case togglePin
    case exportJPG
    case exportPNG
    case share
    case delete
}
