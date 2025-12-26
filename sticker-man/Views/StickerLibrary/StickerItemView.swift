//
//  StickerItemView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// 显示模式
enum StickerDisplayMode {
    case grid
    case list
}

/// 单个表情包视图项
struct StickerItemView: View {
    let sticker: Sticker
    var displayMode: StickerDisplayMode = .grid
    var isSelectionMode: Bool = false
    var isSelected: Bool = false

    @State private var thumbnail: UIImage?
    @State private var isLoading = true

    var body: some View {
        Group {
            if displayMode == .grid {
                gridView
            } else {
                listView
            }
        }
        .task(id: sticker.id) {
            await loadThumbnail()
        }
    }

    // MARK: - Grid View
    private var gridView: some View {
        ZStack(alignment: .topTrailing) {
            // 缩略图
            thumbnailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 置顶标记或选择标记
            if isSelectionMode {
                selectionOverlay
            } else if sticker.isPinned {
                pinnedBadge
            }
        }
        .cornerRadius(8)
    }

    // MARK: - List View
    private var listView: some View {
        HStack(spacing: 12) {
            // 缩略图
            ZStack {
                thumbnailView
                    .frame(width: 60, height: 60)
                    .clipped()

                // 选择标记
                if isSelectionMode {
                    selectionOverlay
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

                    if sticker.isPinned && !isSelectionMode {
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

            if !isSelectionMode {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Subviews
    private var thumbnailView: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
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
        }
    }

    private var pinnedBadge: some View {
        Image(systemName: "pin.fill")
            .font(.caption)
            .foregroundColor(.white)
            .padding(6)
            .background(Color.red)
            .clipShape(Circle())
            .padding(6)
            .transition(.scale.combined(with: .opacity))
    }

    private var selectionOverlay: some View {
        ZStack(alignment: displayMode == .grid ? .topTrailing : .center) {
            if displayMode == .grid {
                Color.black.opacity(isSelected ? 0.3 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(displayMode == .grid ? .title2 : .title3)
                .foregroundColor(isSelected ? .blue : .gray)
                .padding(displayMode == .grid ? 6 : 0)
                .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }

    // MARK: - Helpers
    private func loadThumbnail() async {
        isLoading = true
        defer { isLoading = false }

        thumbnail = await FileStorageManager.shared.loadThumbnail(for: sticker.id)
    }

    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
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
