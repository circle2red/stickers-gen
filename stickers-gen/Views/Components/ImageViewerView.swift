//
//  ImageViewerView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// 图片查看器（全屏查看，支持左右滑动）
struct ImageViewerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: StickerLibraryViewModel

    let initialIndex: Int
    var onMenuAction: (MenuAction, Sticker) -> Void

    @State private var currentIndex: Int

    init(viewModel: StickerLibraryViewModel, initialIndex: Int, onMenuAction: @escaping (MenuAction, Sticker) -> Void) {
        self.viewModel = viewModel
        self.initialIndex = initialIndex
        self.onMenuAction = onMenuAction
        self._currentIndex = State(initialValue: initialIndex)
    }

    var currentSticker: Sticker? {
        guard !viewModel.filteredStickers.isEmpty,
              currentIndex >= 0,
              currentIndex < viewModel.filteredStickers.count else {
            return nil
        }
        return viewModel.filteredStickers[currentIndex]
    }

    var body: some View {
        NavigationStack {
            // 如果没有图片，显示空状态
            if viewModel.filteredStickers.isEmpty {
                VStack {
                    Text("没有可显示的图片")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.ignoresSafeArea())
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()

                    // TabView 实现左右滑动
                    TabView(selection: $currentIndex) {
                        ForEach(Array(viewModel.filteredStickers.enumerated()), id: \.element.id) { index, sticker in
                            StickerImageView(sticker: sticker)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // 顶部信息栏
                    VStack {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }

                            Spacer()

                            if let currentSticker = currentSticker {
                                VStack(alignment: .center, spacing: 2) {
                                    Text(currentSticker.filename)
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Text("\(currentIndex + 1) / \(viewModel.filteredStickers.count)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            Spacer()

                            Button {
                                showingMenu = true
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        .padding()

                        Spacer()
                    }
                }
                .navigationBarHidden(true)
                .statusBar(hidden: true)
            }
        }
        .confirmationDialog(
            currentSticker?.filename ?? "操作",
            isPresented: $showingMenu,
            titleVisibility: .visible
        ) {
            if let sticker = currentSticker {
                Button("编辑标签") {
                    onMenuAction(.editTags, sticker)
                }

                Button("编辑图片") {
                    onMenuAction(.editImage, sticker)
                }

                Button(sticker.isPinned ? "取消置顶" : "置顶") {
                    onMenuAction(.togglePin, sticker)
                }

                Button("导出为JPG") {
                    onMenuAction(.exportJPG, sticker)
                }

                Button("导出为PNG") {
                    onMenuAction(.exportPNG, sticker)
                }

                Button("分享") {
                    onMenuAction(.share, sticker)
                }

                Button("删除", role: .destructive) {
                    onMenuAction(.delete, sticker)
                }
            }

            Button("取消", role: .cancel) {}
        }
    }

    @State private var showingMenu = false
}

/// 单个表情包图片视图
struct StickerImageView: View {
    let sticker: Sticker
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .scaleEffect(scale)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    // 限制缩放范围
                                    if scale < 1.0 {
                                        withAnimation {
                                            scale = 1.0
                                            lastScale = 1.0
                                        }
                                    } else if scale > 3.0 {
                                        withAnimation {
                                            scale = 3.0
                                            lastScale = 3.0
                                        }
                                    }
                                }
                        )
                        .onTapGesture(count: 2) {
                            // 双击重置缩放
                            withAnimation {
                                scale = 1.0
                                lastScale = 1.0
                            }
                        }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .task {
            image = await FileStorageManager.shared.loadImage(at: sticker.filePath)
        }
    }
}

/// 菜单操作类型
enum MenuAction: Equatable {
    case editTags
    case editImage
    case togglePin
    case exportJPG
    case exportPNG
    case share
    case delete
}

#Preview {
    // 创建一个简化的包装视图来处理预览
    struct PreviewWrapper: View {
        @StateObject private var viewModel = StickerLibraryViewModel()

        var body: some View {
            Color.clear
                .onAppear {
                    // 在视图出现时设置测试数据
                    viewModel.stickers = [
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
                        )
                    ]
                    viewModel.filteredStickers = viewModel.stickers
                }
                .fullScreenCover(isPresented: .constant(true)) {
                    ImageViewerView(
                        viewModel: viewModel,
                        initialIndex: 0,
                        onMenuAction: { _, _ in }
                    )
                }
        }
    }

    return PreviewWrapper()
}
