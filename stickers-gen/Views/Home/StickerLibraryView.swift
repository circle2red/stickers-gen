//
//  StickerLibraryView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// 表情包图库视图（从HomeView提取）
struct StickerLibraryView: View {
    @StateObject private var viewModel = StickerLibraryViewModel()

    // Sheet states
    @State private var showingTagEditor = false
    @State private var showingActionSheet = false
    @State private var showingImport = false
    @State private var showingImageViewer = false
    @State private var showingEditor = false
    @State private var selectedSticker: Sticker?
    @State private var selectedStickerIndex: Int = 0
    @State private var editingTags: [String] = []
    @State private var allTags: [String] = []
    @State private var editorImage: UIImage?

    // Share
    @State private var shareItem: URL?
    @State private var showingShareSheet = false

    var body: some View {
        ZStack {
            if viewModel.isEmpty {
                // 空状态
                EmptyStateView {
                    showingImport = true
                }
            } else {
                // 内容视图
                VStack(spacing: 0) {
                    // 搜索栏
                    SearchBar(
                        searchText: $viewModel.searchText,
                        suggestions: viewModel.searchSuggestions,
                        onSuggestionTap: { suggestion in
                            viewModel.applySearchSuggestion(suggestion)
                        }
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    // 列表内容
                    if viewModel.viewMode == .grid {
                        GridView(
                            stickers: viewModel.filteredStickers,
                            onStickerTap: { sticker in
                                handleStickerTap(sticker)
                            },
                            onStickerLongPress: { sticker in
                                handleStickerLongPress(sticker)
                            }
                        )
                    } else {
                        ListMenuView(
                            stickers: viewModel.filteredStickers,
                            onStickerTap: { sticker in
                                handleStickerTap(sticker)
                            },
                            onStickerLongPress: { sticker in
                                handleStickerLongPress(sticker)
                            }
                        )
                    }
                }
            }

            // 加载指示器
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.isEmpty {
                    Button(action: {
                        viewModel.toggleViewMode()
                    }) {
                        Image(systemName: viewModel.viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                            .font(.title3)
                    }
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(isPresented: $showingTagEditor) {
            TagEditorView(tags: $editingTags, allTags: allTags)
                .onDisappear {
                    // 保存标签
                    if let sticker = selectedSticker {
                        Task {
                            await viewModel.updateStickerTags(sticker, tags: editingTags)
                        }
                    }
                }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let shareItem = shareItem {
                ShareSheet(items: [shareItem])
            }
        }
        .sheet(isPresented: $showingImport) {
            ImportView()
                .onDisappear {
                    // 导入完成后刷新列表
                    Task {
                        await viewModel.refresh()
                    }
                }
        }
        .fullScreenCover(isPresented: $showingImageViewer) {
            ImageViewerView(
                viewModel: viewModel,
                initialIndex: selectedStickerIndex,
                onMenuAction: { action, sticker in
                    handleMenuAction(action, sticker: sticker)
                }
            )
        }
        .fullScreenCover(isPresented: $showingEditor) {
            if let editorImage = editorImage {
                EditorView(image: editorImage, sticker: selectedSticker)
                    .onDisappear {
                        // 编辑完成后刷新列表
                        Task {
                            await viewModel.refresh()
                        }
                    }
            }
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .confirmationDialog(
            selectedSticker?.filename ?? "操作",
            isPresented: $showingActionSheet,
            titleVisibility: .visible
        ) {
            if let sticker = selectedSticker {
                Button("编辑标签") {
                    handleEditTags(sticker)
                }

                Button("编辑图片") {
                    handleEditImage(sticker)
                }

                Button(sticker.isPinned ? "取消置顶" : "置顶") {
                    handleTogglePin(sticker)
                }

                Button("导出为JPG") {
                    handleExport(sticker, format: "jpg")
                }

                Button("导出为PNG") {
                    handleExport(sticker, format: "png")
                }

                Button("分享") {
                    handleShare(sticker)
                }

                Button("删除", role: .destructive) {
                    handleDelete(sticker)
                }

                Button("取消", role: .cancel) {}
            }
        }
    }

    // MARK: - Actions
    private func handleStickerTap(_ sticker: Sticker) {
        // 找到当前图片在列表中的索引
        if let index = viewModel.filteredStickers.firstIndex(where: { $0.id == sticker.id }) {
            selectedStickerIndex = index
            showingImageViewer = true
        }
    }

    private func handleStickerLongPress(_ sticker: Sticker) {
        selectedSticker = sticker
        showingActionSheet = true
    }

    private func handleEditTags(_ sticker: Sticker) {
        selectedSticker = sticker
        editingTags = sticker.tags
        Task {
            allTags = await viewModel.getAllTags()
            showingTagEditor = true
        }
    }

    private func handleEditImage(_ sticker: Sticker) {
        Task {
            if let image = await FileStorageManager.shared.loadImage(at: sticker.filePath) {
                selectedSticker = sticker
                editorImage = image
                showingEditor = true
            }
        }
    }

    private func handleTogglePin(_ sticker: Sticker) {
        Task {
            await viewModel.togglePin(sticker)
        }
    }

    private func handleExport(_ sticker: Sticker, format: String) {
        Task {
            if let url = await viewModel.exportSticker(sticker, format: format) {
                shareItem = url
                showingShareSheet = true
            }
        }
    }

    private func handleShare(_ sticker: Sticker) {
        Task {
            if let url = await viewModel.exportSticker(sticker, format: "jpg") {
                shareItem = url
                showingShareSheet = true
            }
        }
    }

    private func handleDelete(_ sticker: Sticker) {
        Task {
            await viewModel.deleteSticker(sticker)
        }
    }

    private func handleMenuAction(_ action: MenuAction, sticker: Sticker) {
        // 需要关闭查看器的操作
        if action == .delete || action == .editTags || action == .editImage {
            showingImageViewer = false
        }

        // 执行对应操作
        switch action {
        case .editTags:
            handleEditTags(sticker)
        case .editImage:
            handleEditImage(sticker)
        case .togglePin:
            handleTogglePin(sticker)
        case .exportJPG:
            handleExport(sticker, format: "jpg")
        case .exportPNG:
            handleExport(sticker, format: "png")
        case .share:
            handleShare(sticker)
        case .delete:
            handleDelete(sticker)
        }
    }
}

#Preview {
    StickerLibraryView()
}
