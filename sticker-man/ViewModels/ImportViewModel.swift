//
//  ImportViewModel.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import Foundation
import SwiftUI
import PhotosUI
import Zip

/// 导入视图模型
@MainActor
class ImportViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isImporting = false
    @Published var importProgress: Double = 0
    @Published var importedCount = 0
    @Published var totalCount = 0
    @Published var currentFileName = ""
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var showGifWarning = false
    @Published var hasGifFiles = false

    // MARK: - Services
    private let databaseManager = DatabaseManager.shared
    private let fileStorageManager = FileStorageManager.shared

    // MARK: - Photo Picker
    /// 导入选中的照片
    func importPhotos(_ items: [PhotosPickerItem]) async {
        isImporting = true
        totalCount = items.count
        importedCount = 0
        hasGifFiles = false
        defer { isImporting = false }

        var stickers: [Sticker] = []

        for (index, item) in items.enumerated() {
            do {
                // 加载图片数据
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    print("⚠️ Failed to load image from PhotosPicker")
                    continue
                }

                // 检测GIF文件
                if isGifData(data) {
                    hasGifFiles = true
                }

                // 生成文件名
                let filename = "photo_\(Date().unixTimestamp)_\(index).jpg"
                currentFileName = filename

                // 保存图片
                let sticker = try await fileStorageManager.saveImage(image, filename: filename)
                stickers.append(sticker)

                importedCount += 1
                importProgress = Double(importedCount) / Double(totalCount)
            } catch {
                print("❌ Failed to import photo: \(error)")
            }
        }

        // 批量插入数据库
        if !stickers.isEmpty {
            do {
                try await databaseManager.insertStickers(stickers)
                print("✅ Imported \(stickers.count) photos")
            } catch {
                showErrorMessage("数据库保存失败: \(error.localizedDescription)")
            }
        }

        // 如果检测到GIF文件，显示警告
        if hasGifFiles {
            showGifWarning = true
        }
    }

    // MARK: - Document Picker
    /// 导入选中的文件
    func importDocuments(_ urls: [URL]) async {
        isImporting = true
        totalCount = urls.count
        importedCount = 0
        hasGifFiles = false
        defer { isImporting = false }

        var stickers: [Sticker] = []

        for url in urls {
            // 开始访问安全作用域资源
            guard url.startAccessingSecurityScopedResource() else {
                print("⚠️ Failed to access security scoped resource: \(url.lastPathComponent)")
                continue
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let filename = url.lastPathComponent
                currentFileName = filename

                // 判断文件类型
                let fileExtension = url.pathExtension.lowercased()

                if fileExtension == "zip" {
                    // ZIP文件，批量导入
                    do {
                        let importedStickers = try await importZipFile(url)
                        stickers.append(contentsOf: importedStickers)
                    } catch let error as ImportError {
                        showErrorMessage(error.localizedDescription ?? "ZIP导入失败")
                    } catch {
                        showErrorMessage("ZIP导入失败: \(error.localizedDescription)")
                    }
                } else if ["jpg", "jpeg", "png", "gif"].contains(fileExtension) {
                    // 检测GIF文件
                    if fileExtension == "gif" {
                        hasGifFiles = true
                    }

                    // 图片文件
                    guard let image = UIImage(contentsOfFile: url.path) else {
                        print("⚠️ Failed to load image: \(filename)")
                        continue
                    }

                    // 生成唯一的文件名
                    let uniqueFilename = await makeUniqueFilename(filename)

                    let sticker = try await fileStorageManager.saveImage(image, filename: uniqueFilename)
                    stickers.append(sticker)

                    importedCount += 1
                    importProgress = Double(importedCount) / Double(totalCount)
                } else {
                    print("⚠️ Unsupported file type: \(fileExtension)")
                }
            } catch {
                print("❌ Failed to import document: \(error)")
            }
        }

        // 批量插入数据库
        if !stickers.isEmpty {
            do {
                try await databaseManager.insertStickers(stickers)
                print("✅ Imported \(stickers.count) files")
            } catch {
                showErrorMessage("数据库保存失败: \(error.localizedDescription)")
            }
        }

        // 如果检测到GIF文件，显示警告
        if hasGifFiles {
            showGifWarning = true
        }
    }

    // MARK: - ZIP Import
    /// 导入ZIP文件
    private func importZipFile(_ url: URL) async throws -> [Sticker] {
        currentFileName = url.lastPathComponent

        // 创建临时目录
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // 解压ZIP
        do {
            try await unzipFile(at: url, to: tempDir)
        } catch {
            print("❌ Failed to unzip file: \(error)")
            throw ImportError.unzipFailed
        }

        // 查找所有图片文件
        let imageURLs = try findImageFiles(in: tempDir)

        // 检查是否找到图片
        if imageURLs.isEmpty {
            print("⚠️ No images found in ZIP file")
            throw ImportError.noImagesFound
        }

        totalCount = imageURLs.count
        print("📦 Found \(totalCount) images in ZIP file")

        var stickers: [Sticker] = []

        for imageURL in imageURLs {
            // 检测GIF文件
            if imageURL.pathExtension.lowercased() == "gif" {
                hasGifFiles = true
            }

            guard let image = UIImage(contentsOfFile: imageURL.path) else {
                print("⚠️ Failed to load image: \(imageURL.lastPathComponent)")
                continue
            }

            let filename = imageURL.lastPathComponent
            currentFileName = filename

            // 生成唯一的文件名
            let uniqueFilename = await makeUniqueFilename(filename)

            let sticker = try await fileStorageManager.saveImage(image, filename: uniqueFilename)
            stickers.append(sticker)

            importedCount += 1
            importProgress = Double(importedCount) / Double(totalCount)
        }

        print("✅ Successfully imported \(stickers.count) images from ZIP")
        return stickers
    }

    /// 解压ZIP文件
    private func unzipFile(at sourceURL: URL, to destinationURL: URL) async throws {
        // 使用 Zip 库解压文件
        try Zip.unzipFile(sourceURL, destination: destinationURL, overwrite: true, password: nil)
        print("✅ Unzipped file: \(sourceURL.lastPathComponent)")
    }

    /// 查找目录中的所有图片文件
    private func findImageFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey])

        var imageURLs: [URL] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            let fileExtension = fileURL.pathExtension.lowercased()
            if ["jpg", "jpeg", "png", "gif"].contains(fileExtension) {
                imageURLs.append(fileURL)
            }
        }

        return imageURLs
    }

    // MARK: - Error Handling
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        print("❌ \(message)")
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }

    func clearGifWarning() {
        showGifWarning = false
        hasGifFiles = false
    }

    // MARK: - Helpers
    /// 检测数据是否为GIF格式
    private func isGifData(_ data: Data) -> Bool {
        guard data.count >= 6 else { return false }

        // GIF文件的magic number: "GIF87a" or "GIF89a"
        let gifHeader = [UInt8](data.prefix(6))
        return gifHeader[0] == 0x47 && // 'G'
               gifHeader[1] == 0x49 && // 'I'
               gifHeader[2] == 0x46    // 'F'
    }

    /// 生成唯一的文件名（如果文件名已存在，添加时间戳后缀）
    private func makeUniqueFilename(_ originalFilename: String) async -> String {
        let nameWithoutExt = (originalFilename as NSString).deletingPathExtension
        let ext = (originalFilename as NSString).pathExtension

        // 首先检查原始文件名是否存在
        do {
            let exists = try await databaseManager.filenameExists(originalFilename)
            if !exists {
                return originalFilename
            }

            // 文件名已存在，尝试添加时间戳
            let timestamp = Date().unixTimestamp
            let filenameWithTimestamp: String
            if ext.isEmpty {
                filenameWithTimestamp = "\(nameWithoutExt)_\(timestamp)"
            } else {
                filenameWithTimestamp = "\(nameWithoutExt)_\(timestamp).\(ext)"
            }

            let existsWithTimestamp = try await databaseManager.filenameExists(filenameWithTimestamp)
            if !existsWithTimestamp {
                return filenameWithTimestamp
            }

            // 时间戳也存在，使用UUID
            let uniqueId = UUID().uuidString.prefix(8)
            if ext.isEmpty {
                return "\(nameWithoutExt)_\(uniqueId)"
            } else {
                return "\(nameWithoutExt)_\(uniqueId).\(ext)"
            }
        } catch {
            print("⚠️ Failed to check filename existence: \(error)")
            // 如果检查失败，直接使用带时间戳的文件名
            let timestamp = Date().unixTimestamp
            if ext.isEmpty {
                return "\(nameWithoutExt)_\(timestamp)"
            } else {
                return "\(nameWithoutExt)_\(timestamp).\(ext)"
            }
        }
    }

    // MARK: - Reset
    func reset() {
        isImporting = false
        importProgress = 0
        importedCount = 0
        totalCount = 0
        currentFileName = ""
        hasGifFiles = false
        showGifWarning = false
    }
}

// MARK: - Import Error
enum ImportError: Error, LocalizedError {
    case noImagesFound
    case invalidFile
    case unzipFailed

    var errorDescription: String? {
        switch self {
        case .noImagesFound:
            return "ZIP文件中未找到任何图片文件"
        case .invalidFile:
            return "无效的文件"
        case .unzipFailed:
            return "ZIP文件解压失败"
        }
    }
}
