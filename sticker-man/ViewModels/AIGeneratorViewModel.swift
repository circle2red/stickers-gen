//
//  AIGeneratorViewModel.swift
//  stickers-gen
//
//  Created on 2025/12/30.
//

import Foundation
import SwiftUI
import PhotosUI

/// AI创作视图模型
@MainActor
class AIGeneratorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var prompt: String = ""
    @Published var selectedImage: UIImage?
    @Published var generatedImage: UIImage?
    @Published var isGenerating = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var showStickerPicker = false
    @Published var availableStickers: [Sticker] = []
    @Published var isLoadingStickers = false

    // MARK: - Services
    private let aiService = AIService.shared
    private let fileStorageManager = FileStorageManager.shared
    private let databaseManager = DatabaseManager.shared

    // MARK: - AI Config
    var aiConfig: AIConfig {
        return AIConfig.load()
    }

    // MARK: - Computed Properties
    var canGenerate: Bool {
        return !prompt.isEmpty && !isGenerating && aiConfig.isValid
    }

    var hasGeneratedImage: Bool {
        return generatedImage != nil
    }

    // MARK: - Methods

    /// 生成AI图片
    func generateImage() async {
        guard canGenerate else {
            showErrorMessage("请输入提示词并确保AI配置正确")
            return
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let image = try await aiService.generateImage(
                prompt: prompt,
                baseImage: selectedImage,
                config: aiConfig
            )

            generatedImage = image
            print("[OK] AI image generated successfully")

        } catch let error as AIError {
            showErrorMessage(error.errorDescription ?? "生成失败")
        } catch {
            showErrorMessage("生成失败: \(error.localizedDescription)")
        }
    }

    /// 保存生成的图片为新表情包
    func saveGeneratedImage() async {
        guard let image = generatedImage else {
            showErrorMessage("没有可保存的图片")
            return
        }

        do {
            // 生成默认文件名
            let timestamp = Date().unixTimestamp
            let filename = "AI_generated_\(timestamp).jpg"

            // 保存图片文件
            let sticker = try await fileStorageManager.saveImage(image, filename: filename)

            // 保存到数据库
            try await databaseManager.insertSticker(sticker)

            print("[OK] AI generated sticker saved: \(filename)")
            showSuccessAlert = true

            // 清空生成的图片
            generatedImage = nil

        } catch {
            showErrorMessage("保存失败: \(error.localizedDescription)")
        }
    }

    /// 清除选中的图片
    func clearSelectedImage() {
        selectedImage = nil
        selectedPhotoItem = nil
    }

    /// 清除生成的图片
    func clearGeneratedImage() {
        generatedImage = nil
    }

    /// 从PhotosPickerItem加载图片
    func loadSelectedImage() async {
        guard let photoItem = selectedPhotoItem else { return }

        do {
            if let data = try await photoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
                print("[OK] Image loaded from picker")
            }
        } catch {
            showErrorMessage("加载图片失败: \(error.localizedDescription)")
        }
    }

    /// 加载所有表情包
    func loadAvailableStickers() async {
        isLoadingStickers = true
        defer { isLoadingStickers = false }

        do {
            availableStickers = try await databaseManager.fetchAllStickers()
            print("[OK] Loaded \(availableStickers.count) stickers for selection")
        } catch {
            showErrorMessage("加载表情包失败: \(error.localizedDescription)")
        }
    }

    /// 从表情包选择基础图片
    func selectStickerAsBaseImage(_ sticker: Sticker) async {
        guard let image = await fileStorageManager.loadImage(at: sticker.filePath) else {
            showErrorMessage("加载表情包图片失败")
            return
        }

        selectedImage = image
        showStickerPicker = false
        print("[OK] Selected sticker as base image: \(sticker.filename)")
    }

    // MARK: - Error Handling
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        print("[ERROR] \(message)")
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}
