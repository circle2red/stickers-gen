//
//  ListMenuView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// 列表视图（单列）
struct ListMenuView: View {
    let stickers: [Sticker]
    var isSelectionMode: Bool = false
    var selectedStickers: Set<String> = []
    var onStickerTap: (Sticker) -> Void
    var onStickerLongPress: (Sticker) -> Void

    var body: some View {
        List(stickers) { sticker in
            StickerItemView(
                sticker: sticker,
                displayMode: .list,
                isSelectionMode: isSelectionMode,
                isSelected: selectedStickers.contains(sticker.id)
            )
            .onTapGesture {
                onStickerTap(sticker)
            }
            .onLongPressGesture {
                onStickerLongPress(sticker)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .id("\(sticker.id)-\(sticker.isPinned)-\(sticker.modifiedAt)")
        }
        .listStyle(.plain)
    }
}

#Preview {
    ListMenuView(
        stickers: [
            Sticker(
                id: "1",
                filename: "funny_cat.jpg",
                filePath: "test1.jpg",
                fileSize: 50000,
                width: 500,
                height: 500,
                format: "jpg",
                tags: ["搞笑", "猫咪"]
            ),
            Sticker(
                id: "2",
                filename: "cute_dog.jpg",
                filePath: "test2.jpg",
                fileSize: 60000,
                width: 500,
                height: 500,
                format: "jpg",
                isPinned: true,
                tags: ["可爱"]
            )
        ],
        onStickerTap: { _ in },
        onStickerLongPress: { _ in }
    )
}
