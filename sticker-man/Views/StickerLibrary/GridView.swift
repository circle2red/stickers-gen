//
//  GridView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// 网格视图（3列）
struct GridView: View {
    let stickers: [Sticker]
    var onStickerTap: (Sticker) -> Void
    var onStickerLongPress: (Sticker) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: Constants.UI.gridColumns)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(stickers) { sticker in
                    StickerItemView(sticker: sticker)
                        .aspectRatio(1, contentMode: .fill)
                        .onTapGesture {
                            onStickerTap(sticker)
                        }
                        .onLongPressGesture {
                            onStickerLongPress(sticker)
                        }
                        .id("\(sticker.id)-\(sticker.isPinned)-\(sticker.modifiedAt)")
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
}

#Preview {
    GridView(
        stickers: [
            Sticker(
                id: "1",
                filename: "test1.jpg",
                filePath: "test1.jpg",
                fileSize: 50000,
                width: 500,
                height: 500,
                format: "jpg"
            ),
            Sticker(
                id: "2",
                filename: "test2.jpg",
                filePath: "test2.jpg",
                fileSize: 60000,
                width: 500,
                height: 500,
                format: "jpg",
                isPinned: true
            ),
            Sticker(
                id: "3",
                filename: "test3.jpg",
                filePath: "test3.jpg",
                fileSize: 70000,
                width: 500,
                height: 500,
                format: "jpg"
            )
        ],
        onStickerTap: { _ in },
        onStickerLongPress: { _ in }
    )
}
