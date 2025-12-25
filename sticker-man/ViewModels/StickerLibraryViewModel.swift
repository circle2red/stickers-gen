//
//  StickerLibraryViewModel.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import Foundation
import SwiftUI
import Combine

/// 表情库视图模型
@MainActor
class StickerLibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var stickers: [Sticker] = []
    @Published var filteredStickers: [Sticker] = []
    @Published var searchText: String = ""
    @Published var searchSuggestions: [String] = []
    @Published var viewMode: ViewMode = .grid
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let databaseManager = DatabaseManager.shared
    private let fileStorageManager = FileStorageManager.shared

    // MARK: - View Mode
    enum ViewMode {
        case grid
        case list
    }

    // MARK: - Initialization
    init() {
        setupSearchDebounce()
        Task {
            await loadStickers()
        }
    }

    // MARK: - Setup
    /// 设置搜索防抖
    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(Constants.UI.searchDebounceMilliseconds), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                Task { @MainActor in
                    await self?.performSearch(searchText)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading
    /// 加载所有表情包
    func loadStickers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            stickers = try await databaseManager.fetchAllStickers()
            filteredStickers = stickers
            print("✅ Loaded \(stickers.count) stickers")
        } catch {
            showErrorMessage("加载表情包失败: \(error.localizedDescription)")
        }
    }

    /// 刷新列表
    func refresh() async {
        await loadStickers()
    }

    // MARK: - Search
    /// 执行搜索
    private func performSearch(_ query: String) async {
        // 如果搜索为空，显示所有表情
        if query.isEmpty {
            filteredStickers = stickers
            searchSuggestions = []
            return
        }

        // 搜索标签建议
        do {
            searchSuggestions = try await databaseManager.searchTags(query: query)
        } catch {
            print("❌ Failed to fetch search suggestions: \(error)")
        }

        // 按标签搜索表情包
        do {
            filteredStickers = try await databaseManager.searchStickers(byTag: query)
        } catch {
            showErrorMessage("搜索失败: \(error.localizedDescription)")
        }
    }

    /// 应用搜索建议
    func applySearchSuggestion(_ suggestion: String) {
        searchText = suggestion
    }

    // MARK: - View Mode
    /// 切换视图模式
    func toggleViewMode() {
        withAnimation {
            viewMode = viewMode == .grid ? .list : .grid
        }
    }

    // MARK: - Sticker Operations
    /// 删除表情包
    func deleteSticker(_ sticker: Sticker) async {
        do {
            // 删除文件
            try await fileStorageManager.deleteSticker(sticker)

            // 删除数据库记录
            try await databaseManager.deleteSticker(id: sticker.id)

            // 从列表中移除
            stickers.removeAll { $0.id == sticker.id }
            filteredStickers.removeAll { $0.id == sticker.id }

            print("✅ Sticker deleted: \(sticker.filename)")
        } catch {
            showErrorMessage("删除失败: \(error.localizedDescription)")
        }
    }

    /// 置顶/取消置顶表情包
    func togglePin(_ sticker: Sticker) async {
        var updatedSticker = sticker
        updatedSticker.isPinned.toggle()

        do {
            try await databaseManager.updateSticker(updatedSticker)

            // 更新本地数据
            if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
                stickers[index] = updatedSticker
            }
            if let index = filteredStickers.firstIndex(where: { $0.id == sticker.id }) {
                filteredStickers[index] = updatedSticker
            }

            // 重新排序（置顶的在前面）
            await loadStickers()
            await performSearch(searchText)

            print("✅ Sticker pin toggled: \(sticker.filename)")
        } catch {
            showErrorMessage("操作失败: \(error.localizedDescription)")
        }
    }

    /// 更新表情包标签
    func updateStickerTags(_ sticker: Sticker, tags: [String]) async {
        var updatedSticker = sticker
        updatedSticker.tags = tags

        do {
            try await databaseManager.updateSticker(updatedSticker)

            // 更新本地数据
            if let index = stickers.firstIndex(where: { $0.id == sticker.id }) {
                stickers[index] = updatedSticker
            }
            if let index = filteredStickers.firstIndex(where: { $0.id == sticker.id }) {
                filteredStickers[index] = updatedSticker
            }

            print("✅ Sticker tags updated: \(tags.joined(separator: ", "))")
        } catch {
            showErrorMessage("标签更新失败: \(error.localizedDescription)")
        }
    }

    /// 导出表情包
    func exportSticker(_ sticker: Sticker, format: String) async -> URL? {
        do {
            let exportURL = try await fileStorageManager.exportImage(sticker: sticker, format: format)
            print("✅ Sticker exported: \(exportURL.lastPathComponent)")
            return exportURL
        } catch {
            showErrorMessage("导出失败: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Error Handling
    /// 显示错误消息
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ \(message)")
    }

    /// 清除错误
    func clearError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Helper
    /// 检查是否为空状态
    var isEmpty: Bool {
        return stickers.isEmpty
    }

    /// 获取所有标签（用于标签输入提示）
    func getAllTags() async -> [String] {
        do {
            let tags = try await databaseManager.fetchAllTags()
            return tags.map { $0.name }
        } catch {
            print("❌ Failed to fetch tags: \(error)")
            return []
        }
    }
}
