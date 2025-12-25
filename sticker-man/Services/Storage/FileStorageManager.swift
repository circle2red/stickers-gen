//
//  FileStorageManager.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import Foundation
import UIKit

/// 文件存储管理器
actor FileStorageManager {
    static let shared = FileStorageManager()

    private init() {
        Task {
            await setupDirectories()
        }
    }

    // MARK: - Setup
    /// 设置目录结构
    private func setupDirectories() async {
        do {
            let fileManager = FileManager.default
            try fileManager.ensureDirectoryExists(at: URL.appDirectory)
            try fileManager.ensureDirectoryExists(at: URL.stickersDirectory)
            try fileManager.ensureDirectoryExists(at: URL.thumbnailsDirectory)
            print("✅ Storage directories created")
        } catch {
            print("❌ Failed to create directories: \(error)")
        }
    }

    // MARK: - Save Image
    /// 保存图片（导入时）
    /// - Parameters:
    ///   - image: 原始图片
    ///   - filename: 原始文件名
    /// - Returns: Sticker模型（不含tags）
    func saveImage(_ image: UIImage, filename: String) async throws -> Sticker {
        // 生成唯一ID
        let id = String.generateUUID()

        // 压缩图片
        guard let compressed = image.compressed() else {
            throw StorageError.compressionFailed
        }

        let compressedImage = compressed.image
        let imageData = compressed.data

        // 生成文件名（保留原始扩展名，如无则用jpg）
        let fileExtension = filename.fileExtension.isEmpty ? "jpg" : filename.fileExtension
        let newFilename = "\(id).\(fileExtension)"
        let filePath = URL.stickersDirectory.appendingPathComponent(newFilename)

        // 保存压缩后的数据
        try imageData.write(to: filePath)

        // 生成并保存缩略图
        guard let thumbnail = compressedImage.thumbnail() else {
            throw StorageError.thumbnailGenerationFailed
        }

        let thumbnailPath = URL.thumbnailsDirectory.appendingPathComponent("\(id)_thumb.jpg")
        guard let thumbnailData = thumbnail.jpegData() else {
            throw StorageError.dataConversionFailed
        }

        try thumbnailData.write(to: thumbnailPath)

        // 获取图片尺寸和文件大小
        let imageSize = compressedImage.size
        let fileSize = imageData.count

        // 创建Sticker模型
        let sticker = Sticker(
            id: id,
            filename: filename,
            filePath: newFilename,
            fileSize: fileSize,
            width: Int(imageSize.width),
            height: Int(imageSize.height),
            format: fileExtension,
            createdAt: Date().unixTimestamp,
            modifiedAt: Date().unixTimestamp
        )

        print("✅ Image saved: \(newFilename) (\(fileSize) bytes)")
        return sticker
    }

    /// 批量保存图片
    func saveImages(_ images: [(UIImage, String)]) async throws -> [Sticker] {
        var stickers: [Sticker] = []

        for (image, filename) in images {
            let sticker = try await saveImage(image, filename: filename)
            stickers.append(sticker)
        }

        return stickers
    }

    // MARK: - Save Edited Image
    /// 保存编辑后的图片
    /// - Parameters:
    ///   - image: 编辑后的图片
    ///   - originalSticker: 原始表情包（用于更新）
    /// - Returns: 更新后的Sticker模型
    func saveEditedImage(_ image: UIImage, originalSticker: Sticker) async throws -> Sticker {
        // 生成新文件名
        let timestamp = Date().unixTimestamp
        let newFilename = "edit_\(timestamp).jpg"
        let filePath = URL.stickersDirectory.appendingPathComponent(newFilename)

        // 压缩图片
        guard let compressed = image.compressed() else {
            throw StorageError.compressionFailed
        }

        let compressedImage = compressed.image
        let imageData = compressed.data

        // 保存压缩后的数据
        try imageData.write(to: filePath)

        // 生成并保存缩略图
        guard let thumbnail = compressedImage.thumbnail() else {
            throw StorageError.thumbnailGenerationFailed
        }

        let thumbnailPath = URL.thumbnailsDirectory.appendingPathComponent("\(originalSticker.id)_thumb.jpg")
        guard let thumbnailData = thumbnail.jpegData() else {
            throw StorageError.dataConversionFailed
        }

        try thumbnailData.write(to: thumbnailPath)

        // 删除旧图片（保留缩略图，因为会被覆盖）
        try? deleteImageFile(at: originalSticker.filePath)

        // 获取图片尺寸和文件大小
        let imageSize = compressedImage.size
        let fileSize = imageData.count

        // 更新Sticker模型
        var updatedSticker = originalSticker
        updatedSticker.filePath = newFilename
        updatedSticker.fileSize = fileSize
        updatedSticker.width = Int(imageSize.width)
        updatedSticker.height = Int(imageSize.height)
        updatedSticker.format = "jpg"
        updatedSticker.modifiedAt = timestamp

        print("✅ Edited image saved: \(newFilename) (\(fileSize) bytes)")
        return updatedSticker
    }

    // MARK: - Delete
    /// 删除表情包文件
    func deleteSticker(_ sticker: Sticker) async throws {
        // 删除图片文件
        try deleteImageFile(at: sticker.filePath)

        // 删除缩略图
        let thumbnailPath = URL.thumbnailsDirectory.appendingPathComponent("\(sticker.id)_thumb.jpg")
        try? FileManager.default.removeItem(at: thumbnailPath)

        print("✅ Sticker deleted: \(sticker.filePath)")
    }

    /// 删除图片文件
    private func deleteImageFile(at relativePath: String) throws {
        let filePath = URL.stickersDirectory.appendingPathComponent(relativePath)
        if FileManager.default.fileExists(atPath: filePath.path) {
            try FileManager.default.removeItem(at: filePath)
        }
    }

    // MARK: - Load Image
    /// 加载图片
    func loadImage(at relativePath: String) async -> UIImage? {
        let filePath = URL.stickersDirectory.appendingPathComponent(relativePath)
        guard let imageData = try? Data(contentsOf: filePath) else {
            return nil
        }
        return UIImage(data: imageData)
    }

    /// 加载缩略图
    func loadThumbnail(for stickerId: String) async -> UIImage? {
        let thumbnailPath = URL.thumbnailsDirectory.appendingPathComponent("\(stickerId)_thumb.jpg")
        guard let imageData = try? Data(contentsOf: thumbnailPath) else {
            return nil
        }
        return UIImage(data: imageData)
    }

    // MARK: - Export
    /// 导出图片到临时目录
    /// - Parameters:
    ///   - sticker: 表情包
    ///   - format: 导出格式（jpg/png/gif）
    /// - Returns: 临时文件URL
    func exportImage(sticker: Sticker, format: String = "jpg") async throws -> URL {
        guard let image = await loadImage(at: sticker.filePath) else {
            throw StorageError.imageNotFound
        }

        let tempDir = FileManager.default.temporaryDirectory
        let exportFilename = "\(sticker.filename.fileNameWithoutExtension).\(format)"
        let exportPath = tempDir.appendingPathComponent(exportFilename)

        // 根据格式导出
        switch format.lowercased() {
        case "jpg", "jpeg":
            guard let data = image.jpegData() else {
                throw StorageError.dataConversionFailed
            }
            try data.write(to: exportPath)

        case "png":
            guard let data = image.pngData() else {
                throw StorageError.dataConversionFailed
            }
            try data.write(to: exportPath)

        case "gif":
            // GIF导出需要特殊处理，这里先简单导出为JPG
            // 后续在ImageExporter中实现完整的GIF导出
            guard let data = image.jpegData() else {
                throw StorageError.dataConversionFailed
            }
            try data.write(to: exportPath)

        default:
            throw StorageError.unsupportedFormat
        }

        print("✅ Image exported: \(exportPath.lastPathComponent)")
        return exportPath
    }

    // MARK: - Storage Info
    /// 获取存储空间使用情况
    func getStorageInfo() async -> StorageInfo {
        var totalSize: Int64 = 0
        var fileCount = 0

        let fileManager = FileManager.default

        // 计算stickers目录
        if let enumerator = fileManager.enumerator(at: URL.stickersDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            while let fileURL = enumerator.nextObject() as? URL {
                if let size = fileManager.fileSize(at: fileURL) {
                    totalSize += Int64(size)
                    fileCount += 1
                }
            }
        }

        // 计算thumbnails目录
        if let enumerator = fileManager.enumerator(at: URL.thumbnailsDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            while let fileURL = enumerator.nextObject() as? URL {
                if let size = fileManager.fileSize(at: fileURL) {
                    totalSize += Int64(size)
                }
            }
        }

        return StorageInfo(totalSize: totalSize, fileCount: fileCount)
    }

    /// 清除所有缓存
    func clearAllCache() async throws {
        let fileManager = FileManager.default

        // 删除所有文件
        if fileManager.fileExists(atPath: URL.stickersDirectory.path) {
            try fileManager.removeItem(at: URL.stickersDirectory)
        }

        if fileManager.fileExists(atPath: URL.thumbnailsDirectory.path) {
            try fileManager.removeItem(at: URL.thumbnailsDirectory)
        }

        // 重新创建目录
        await setupDirectories()

        print("✅ All cache cleared")
    }
}

// MARK: - Storage Info
struct StorageInfo {
    let totalSize: Int64
    let fileCount: Int

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }
}

// MARK: - Storage Error
enum StorageError: Error, LocalizedError {
    case compressionFailed
    case thumbnailGenerationFailed
    case dataConversionFailed
    case imageNotFound
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "图片压缩失败"
        case .thumbnailGenerationFailed:
            return "缩略图生成失败"
        case .dataConversionFailed:
            return "数据转换失败"
        case .imageNotFound:
            return "图片文件不存在"
        case .unsupportedFormat:
            return "不支持的文件格式"
        }
    }
}
