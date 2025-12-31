//
//  Extensions.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import Foundation
import UIKit
import SwiftUI

// MARK: - String Extensions
extension String {
    /// 生成UUID字符串
    static func generateUUID() -> String {
        return UUID().uuidString
    }

    /// 获取文件扩展名
    var fileExtension: String {
        return (self as NSString).pathExtension
    }

    /// 获取不含扩展名的文件名
    var fileNameWithoutExtension: String {
        return (self as NSString).deletingPathExtension
    }
}

// MARK: - Date Extensions
extension Date {
    /// 转换为Unix时间戳
    var unixTimestamp: Int {
        return Int(self.timeIntervalSince1970)
    }

    /// 从Unix时间戳创建Date
    static func fromUnixTimestamp(_ timestamp: Int) -> Date {
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    /// 格式化为字符串
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
}

// MARK: - UIImage Extensions
extension UIImage {
    /// 压缩图片到指定尺寸和文件大小
    /// - Parameters:
    ///   - maxDimension: 最大边长
    ///   - maxFileSize: 最大文件大小(bytes)
    /// - Returns: (压缩后的图片, 压缩后的数据)
    func compressed(maxDimension: CGFloat = Constants.Storage.maxImageDimension,
                   maxFileSize: Int = Constants.Storage.maxFileSize) -> (image: UIImage, data: Data)? {
        var image = self

        // 1. 如果尺寸超过限制，先缩小尺寸
        if size.width > maxDimension || size.height > maxDimension {
            let scale = maxDimension / max(size.width, size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            image = image.resize(to: newSize) ?? image
        }

        // 2. 压缩文件大小
        var quality: CGFloat = Constants.Storage.compressionQuality
        var imageData = image.jpegData(compressionQuality: quality)

        while let data = imageData, data.count > maxFileSize && quality > 0.1 {
            quality -= 0.1
            imageData = image.jpegData(compressionQuality: quality)
        }

        guard let data = imageData else { return nil }
        guard let finalImage = UIImage(data: data) else { return nil }

        print("[INFO] Compressed: original=\(self.size), final=\(finalImage.size), size=\(data.count) bytes, quality=\(String(format: "%.1f", quality))")

        return (finalImage, data)
    }

    /// 调整图片尺寸
    func resize(to newSize: CGSize) -> UIImage? {
        // 使用 scale=1.0 确保 points 和 pixels 是 1:1 关系
        // 如果使用 0.0，会使用设备原生 scale（如 @3x），导致实际尺寸更大
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// 生成缩略图（裁剪居中）
    func thumbnail(size: CGFloat = Constants.Storage.thumbnailSize) -> UIImage? {
        let targetSize = CGSize(width: size, height: size)

        // 计算裁剪区域
        let scale = max(targetSize.width / self.size.width, targetSize.height / self.size.height)
        let scaledSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        let offset = CGPoint(
            x: (targetSize.width - scaledSize.width) / 2,
            y: (targetSize.height - scaledSize.height) / 2
        )

        // 使用 scale=1.0 确保 points 和 pixels 是 1:1 关系
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: offset, size: scaledSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - URL Extensions
extension URL {
    /// 获取文档目录
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// 获取应用存储目录
    static var appDirectory: URL {
        documentsDirectory.appendingPathComponent(Constants.Storage.appDirectoryName)
    }

    /// 获取表情包存储目录
    static var stickersDirectory: URL {
        appDirectory.appendingPathComponent(Constants.Storage.stickersDirectoryName)
    }

    /// 获取缩略图存储目录
    static var thumbnailsDirectory: URL {
        appDirectory.appendingPathComponent(Constants.Storage.thumbnailsDirectoryName)
    }
}

// MARK: - FileManager Extensions
extension FileManager {
    /// 确保目录存在，不存在则创建
    func ensureDirectoryExists(at url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    /// 获取文件大小
    func fileSize(at url: URL) -> Int? {
        guard let attributes = try? attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attributes[.size] as? Int
    }
}

// MARK: - Color Extensions
extension Color {
    /// 从十六进制创建颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
