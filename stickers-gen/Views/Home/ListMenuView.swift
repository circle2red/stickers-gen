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
    var onStickerTap: (Sticker) -> Void
    var onStickerLongPress: (Sticker) -> Void

    var body: some View {
        List(stickers) { sticker in
            StickerListRow(sticker: sticker)
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

/// 列表行视图
struct StickerListRow: View {
    let sticker: Sticker
    @State private var thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 60)
                        .overlay(
                            ProgressView()
                        )
                }
            }
            .cornerRadius(8)

            // 信息
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sticker.filename)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if sticker.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .transition(.scale.combined(with: .opacity))
                    }
                }

                // 标签
                if !sticker.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(sticker.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                } else {
                    Text("无标签")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // 文件信息
                HStack(spacing: 8) {
                    Text("\(sticker.width)x\(sticker.height)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(formatFileSize(sticker.fileSize))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .task(id: sticker.id) {
            thumbnail = await FileStorageManager.shared.loadThumbnail(for: sticker.id)
        }
    }

    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
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
