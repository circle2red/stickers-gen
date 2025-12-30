//
//  AIService.swift
//  stickers-gen
//
//  Created on 2025/12/30.
//

import Foundation
import UIKit

/// AI服务 - OpenRouter API集成
actor AIService {
    static let shared = AIService()

    private init() {}

    // MARK: - Request/Response Models

    struct GenerateImageRequest: Codable {
        let model: String
        let modalities: [String]
        let messages: [Message]

        struct Message: Codable {
            let role: String
            let content: [Content]

            struct Content: Codable {
                let type: String
                let text: String?
                let imageUrl: ImageURL?

                struct ImageURL: Codable {
                    let url: String
                }
            }
        }
    }

    struct GenerateImageResponse: Codable {
        let id: String
        let choices: [Choice]

        struct Choice: Codable {
            let message: Message

            struct Message: Codable {
                let images: [ImageData]?

                struct ImageData: Codable {
                    let type: String?
                    let imageUrl: ImageURL
                    let index: Int?

                    struct ImageURL: Codable {
                        let url: String
                    }
                }
            }
        }
    }

    // MARK: - Generate Image

    /// 生成AI图片
    /// - Parameters:
    ///   - prompt: 文字提示
    ///   - baseImage: 基础图片（可选）
    ///   - config: AI配置
    /// - Returns: 生成的UIImage
    func generateImage(
        prompt: String,
        baseImage: UIImage? = nil,
        config: AIConfig
    ) async throws -> UIImage {
        guard config.isValid else {
            throw AIError.invalidConfiguration
        }

        // 构建请求内容
        var contentArray: [GenerateImageRequest.Message.Content] = []

        // 添加文字提示
        contentArray.append(
            GenerateImageRequest.Message.Content(
                type: "text",
                text: prompt,
                imageUrl: nil
            )
        )

        // 添加基础图片（如果有）
        if let baseImage = baseImage {
            if let base64String = imageToBase64(baseImage) {
                contentArray.append(
                    GenerateImageRequest.Message.Content(
                        type: "image_url",
                        text: nil,
                        imageUrl: GenerateImageRequest.Message.Content.ImageURL(
                            url: base64String
                        )
                    )
                )
            }
        }

        // 构建请求体
        let request = GenerateImageRequest(
            model: config.modelName,
            modalities: ["image", "text"],
            messages: [
                GenerateImageRequest.Message(
                    role: "user",
                    content: contentArray
                )
            ]
        )

        // 发送请求
        let response = try await sendRequest(request: request, config: config)

        // 解析响应
        guard let imageData = response.choices.first?.message.images?.first else {
            throw AIError.noImageGenerated
        }

        // 从base64解码图片
        let image = try decodeBase64Image(imageData.imageUrl.url)

        return image
    }

    // MARK: - Private Methods

    /// 发送API请求
    private func sendRequest(
        request: GenerateImageRequest,
        config: AIConfig
    ) async throws -> GenerateImageResponse {
        guard let url = URL(string: config.apiEndpoint) else {
            throw AIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = Constants.AI.timeoutSeconds

        // 编码请求体
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)

        // 发送请求
        let (data, urlResponse) = try await URLSession.shared.data(for: urlRequest)

        // 检查HTTP状态码
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // 尝试解析错误消息
            if let errorMessage = String(data: data, encoding: .utf8) {
                print("❌ API Error: \(errorMessage)")
            }
            throw AIError.apiError(statusCode: httpResponse.statusCode)
        }

        // 解码响应
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        do {
            let response = try decoder.decode(GenerateImageResponse.self, from: data)
            return response
        } catch {
            print("❌ Decode error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Response JSON: \(jsonString)")
            }
            throw AIError.decodingFailed
        }
    }

    /// 将UIImage转换为base64字符串
    private func imageToBase64(_ image: UIImage) -> String? {
        // 压缩图片以减少数据量
        guard let compressed = image.compressed() else {
            return nil
        }

        let imageData = compressed.data
        let base64String = imageData.base64EncodedString()

        // 检测图片格式
        let format = detectImageFormat(imageData)

        return "data:image/\(format);base64,\(base64String)"
    }

    /// 检测图片格式
    private func detectImageFormat(_ data: Data) -> String {
        guard let firstByte = data.first else {
            return "jpeg"
        }

        switch firstByte {
        case 0xFF:
            return "jpeg"
        case 0x89:
            return "png"
        case 0x47:
            return "gif"
        case 0x49, 0x4D:
            return "tiff"
        default:
            return "jpeg"
        }
    }

    /// 从base64解码图片
    private func decodeBase64Image(_ base64String: String) throws -> UIImage {
        // 处理data URL格式: data:image/png;base64,xxxxx
        let base64Data: String
        if base64String.hasPrefix("data:") {
            // 提取base64部分
            guard let rangeOfComma = base64String.range(of: ",") else {
                throw AIError.invalidBase64
            }
            base64Data = String(base64String[rangeOfComma.upperBound...])
        } else {
            base64Data = base64String
        }

        // 解码base64
        guard let imageData = Data(base64Encoded: base64Data) else {
            throw AIError.invalidBase64
        }

        guard let image = UIImage(data: imageData) else {
            throw AIError.imageDecodingFailed
        }

        return image
    }

    // MARK: - Test Connection

    /// 测试API连接
    func testConnection(config: AIConfig) async throws -> Bool {
        // 发送一个简单的图像生成测试请求
        let testRequest = GenerateImageRequest(
            model: config.modelName,
            modalities: ["image", "text"],
            messages: [
                GenerateImageRequest.Message(
                    role: "user",
                    content: [
                        GenerateImageRequest.Message.Content(
                            type: "text",
                            text: "A simple test image",
                            imageUrl: nil
                        )
                    ]
                )
            ]
        )

        do {
            let response = try await sendRequest(request: testRequest, config: config)
            // 验证响应中包含图片
            guard response.choices.first?.message.images?.first != nil else {
                throw AIError.noImageGenerated
            }
            return true
        } catch {
            print("❌ Connection test failed: \(error)")
            throw error
        }
    }
}

// MARK: - AI Error

enum AIError: Error, LocalizedError {
    case invalidConfiguration
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case decodingFailed
    case noImageGenerated
    case invalidBase64
    case imageDecodingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "AI配置无效，请检查API设置"
        case .invalidURL:
            return "API端点URL无效"
        case .invalidResponse:
            return "服务器响应无效"
        case .apiError(let statusCode):
            return "API请求失败 (状态码: \(statusCode))"
        case .decodingFailed:
            return "响应解析失败"
        case .noImageGenerated:
            return "未生成图片"
        case .invalidBase64:
            return "Base64数据无效"
        case .imageDecodingFailed:
            return "图片解码失败"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        }
    }
}
