//
//  EditorViewModel.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import Foundation
import SwiftUI
import PencilKit

/// 编辑器视图模型
@MainActor
class EditorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var originalImage: UIImage
    @Published var canvasView = PKCanvasView()
    @Published var textOverlays: [TextOverlay] = []
    @Published var selectedOverlayId: UUID?

    // Tool states
    @Published var currentTool: EditorTool = .none
    @Published var brushColor: Color = .black
    @Published var brushWidth: CGFloat = 4.0
    @Published var showColorPicker = false
    @Published var showTextEditor = false
    @Published var showTextColorPicker = false
    @Published var textColor: Color = .white

    // 白边状态
    @Published var hasBottomPadding = false
    private var imageWithoutPadding: UIImage?

    // Error handling
    @Published var showError = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let fileStorageManager = FileStorageManager.shared
    private let databaseManager = DatabaseManager.shared
    private let originalSticker: Sticker?

    // MARK: - Initialization
    init(image: UIImage, sticker: Sticker? = nil) {
        self.originalImage = image
        self.originalSticker = sticker
        setupCanvasView()
    }

    // MARK: - Setup
    private func setupCanvasView() {
        canvasView.drawing = PKDrawing()
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false

        // 设置工具
        updateTool()
    }

    // MARK: - Tool Management
    func selectTool(_ tool: EditorTool) {
        currentTool = tool

        // 选中画笔或橡皮擦时，取消文本选中
        if tool == .brush || tool == .eraser {
            selectedOverlayId = nil
        }

        // 更新工具（包括禁用/启用 Canvas 交互）
        updateTool()

        // 文本工具：打开文本编辑对话框添加新文本
        if tool == .text {
            showTextEditor = true
        }
    }

    func deselectAllTools() {
        currentTool = .none
        selectedOverlayId = nil
        updateTool()
    }

    private func updateTool() {
        switch currentTool {
        case .brush:
            canvasView.isUserInteractionEnabled = true
            let ink = PKInkingTool(.pen, color: UIColor(brushColor), width: brushWidth)
            canvasView.tool = ink
        case .eraser:
            canvasView.isUserInteractionEnabled = true
            canvasView.tool = PKEraserTool(.bitmap)
        case .none, .text:
            // 禁用 Canvas 交互，防止继续绘画
            canvasView.isUserInteractionEnabled = false
        }
    }

    func updateBrushColor(_ color: Color) {
        brushColor = color
        if currentTool == .brush {
            updateTool()
        }
    }

    func updateBrushWidth(_ width: CGFloat) {
        brushWidth = width
        if currentTool == .brush {
            updateTool()
        }
    }

    func updateTextColor(_ color: Color) {
        textColor = color
        if let selectedId = selectedOverlayId {
            updateTextOverlay(selectedId, color: color)
        }
    }

    // MARK: - Text Overlay Management
    func addTextOverlay(_ text: String) {
        // 计算图片中心位置（基于原始图片尺寸）
        let imageCenter = CGPoint(
            x: originalImage.size.width / 2,
            y: originalImage.size.height / 2
        )

        let overlay = TextOverlay(
            text: text,
            position: imageCenter,
            fontSize: 32,
            color: textColor
        )
        textOverlays.append(overlay)

        // 自动选中新添加的文本
        selectedOverlayId = overlay.id
    }

    func updateTextOverlay(_ id: UUID, text: String? = nil, position: CGPoint? = nil, fontSize: CGFloat? = nil, color: Color? = nil) {
        guard let index = textOverlays.firstIndex(where: { $0.id == id }) else { return }

        if let text = text {
            textOverlays[index].text = text
        }
        if let position = position {
            textOverlays[index].position = position
        }
        if let fontSize = fontSize {
            textOverlays[index].fontSize = fontSize
        }
        if let color = color {
            textOverlays[index].color = color
            textColor = color // 同步更新textColor状态
        }
    }

    func deleteTextOverlay(_ id: UUID) {
        textOverlays.removeAll { $0.id == id }
        // 删除后取消选中所有工具
        if selectedOverlayId == id {
            deselectAllTools()
        }
    }

    // MARK: - Text Overlay Constraints
    /// 确保所有文本框都在图片边界内
    private func constrainTextOverlaysToImageBounds() {
        let imageSize = originalImage.size

        for index in textOverlays.indices {
            let overlay = textOverlays[index]

            // 计算文本的实际尺寸
            let textSize = calculateTextSize(for: overlay)

            // 计算半宽和半高
            let halfWidth = textSize.width / 2
            let halfHeight = textSize.height / 2

            // 计算边界
            let minX = halfWidth
            let maxX = imageSize.width - halfWidth
            let minY = halfHeight
            let maxY = imageSize.height - halfHeight

            // 约束位置
            var newX = overlay.position.x
            var newY = overlay.position.y

            newX = max(minX, min(maxX, newX))
            newY = max(minY, min(maxY, newY))

            // 如果位置有变化，更新位置
            if newX != overlay.position.x || newY != overlay.position.y {
                textOverlays[index].position = CGPoint(x: newX, y: newY)
            }
        }
    }

    /// 计算文本的实际尺寸（包括padding）
    private func calculateTextSize(for overlay: TextOverlay) -> CGSize {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: overlay.fontSize, weight: .bold),
            .strokeWidth: -3.0,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: overlay.text, attributes: attributes)
        let textSize = attributedString.size()

        // 加上padding（每边8点）
        return CGSize(width: textSize.width + 16, height: textSize.height + 16)
    }

    // MARK: - Bottom Padding (白边)
    func toggleBottomPadding() {
        hasBottomPadding.toggle()

        if hasBottomPadding {
            // 添加底部白边
            if imageWithoutPadding == nil {
                imageWithoutPadding = originalImage
            }
            if let paddedImage = addBottomPadding(to: originalImage, percentage: 0.2) {
                originalImage = paddedImage
            }
        } else {
            // 移除底部白边
            if let original = imageWithoutPadding {
                originalImage = original
                imageWithoutPadding = nil
            }
        }

        // 调整白边后，确保所有文本框都在图片边界内
        constrainTextOverlaysToImageBounds()
    }

    private func addBottomPadding(to image: UIImage, percentage: CGFloat) -> UIImage? {
        let paddingHeight = image.size.height * percentage
        let newSize = CGSize(
            width: image.size.width,
            height: image.size.height + paddingHeight
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)

        return renderer.image { context in
            // 填充白色背景
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: newSize))

            // 在顶部绘制原图
            image.draw(at: .zero)
        }
    }

    // MARK: - Export
    func exportImage() -> UIImage? {
        // 创建图形上下文
        let size = originalImage.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            // 1. 绘制背景图片
            originalImage.draw(at: .zero)

            // 2. 绘制 Canvas 内容
            // PKCanvasView 的绘画是在 Canvas 的 frame 尺寸下进行的
            // 我们需要将它缩放到原始图片尺寸
            let canvasFrame = canvasView.frame
            if canvasFrame.width > 0 && canvasFrame.height > 0 {
                // 计算缩放比例
                let scaleX = size.width / canvasFrame.width
                let scaleY = size.height / canvasFrame.height

                // 保存当前上下文状态
                context.cgContext.saveGState()

                // 应用缩放变换
                context.cgContext.scaleBy(x: scaleX, y: scaleY)

                // 绘制 Canvas 内容（在缩放后的坐标系中）
                let canvasRect = CGRect(origin: .zero, size: canvasFrame.size)
                let canvasImage = canvasView.drawing.image(from: canvasRect, scale: 1.0)
                canvasImage.draw(at: .zero)

                // 恢复上下文状态
                context.cgContext.restoreGState()
            }

            // 3. 绘制文本层
            for overlay in textOverlays {
                drawTextOverlay(overlay, in: context.cgContext)
            }
        }
    }

    private func drawTextOverlay(_ overlay: TextOverlay, in context: CGContext) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        // 添加描边效果
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: overlay.fontSize, weight: .bold),
            .foregroundColor: UIColor(overlay.color),
            .strokeColor: UIColor.black,
            .strokeWidth: -3.0, // 负值表示同时填充和描边
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: overlay.text, attributes: attributes)

        // 计算文本尺寸以便居中绘制
        let textSize = attributedString.size()
        let drawPoint = CGPoint(
            x: overlay.position.x - textSize.width / 2,
            y: overlay.position.y - textSize.height / 2
        )

        attributedString.draw(at: drawPoint)
    }

    // MARK: - Save
    func save() async -> Bool {
        guard let exportedImage = exportImage() else {
            showErrorMessage("导出图片失败")
            return false
        }

        do {
            // 始终保存为新表情包（副本）
            let timestamp = Date().unixTimestamp
            let filename = originalSticker?.filename ?? "edited_\(timestamp).jpg"
            let newFilename: String

            if let originalName = originalSticker?.filename.fileNameWithoutExtension {
                newFilename = "\(originalName)_edited_\(timestamp).jpg"
            } else {
                newFilename = "edited_\(timestamp).jpg"
            }

            let newSticker = try await fileStorageManager.saveImage(exportedImage, filename: newFilename)
            try await databaseManager.insertSticker(newSticker)

            print("[OK] Image saved as new sticker: \(newFilename)")
            return true
        } catch {
            showErrorMessage("保存失败: \(error.localizedDescription)")
            return false
        }
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

// MARK: - Editor Tool
enum EditorTool {
    case none
    case brush
    case eraser
    case text
}

// MARK: - Text Overlay Model
struct TextOverlay: Identifiable {
    let id = UUID()
    var text: String
    var position: CGPoint
    var fontSize: CGFloat
    var color: Color
    var rotation: Double = 0
    var scale: CGFloat = 1.0
}
