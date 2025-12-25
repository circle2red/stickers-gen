//
//  StickerItemView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// 单个表情包视图项
struct StickerItemView: View {
    let sticker: Sticker
    @State private var thumbnail: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 缩略图
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
            } else {
                // 加载失败显示占位图
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGray6))
            }

            // 置顶标记
            if sticker.isPinned {
                Image(systemName: "pin.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Color.red)
                    .clipShape(Circle())
                    .padding(6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .cornerRadius(8)
        .task(id: sticker.id) {
            await loadThumbnail()
        }
    }

    // MARK: - Load Thumbnail
    private func loadThumbnail() async {
        isLoading = true
        defer { isLoading = false }

        thumbnail = await FileStorageManager.shared.loadThumbnail(for: sticker.id)
    }
}

// MARK: - Preview
#Preview {
    StickerItemView(
        sticker: Sticker(
            id: "preview-id",
            filename: "preview.jpg",
            filePath: "preview.jpg",
            fileSize: 50000,
            width: 500,
            height: 500,
            format: "jpg",
            isPinned: true
        )
    )
    .frame(width: 120, height: 120)
    .padding()
}
