//
//  EditorCanvasView.swift
//  stickers-gen
//
//  Created on 2025/12/26.
//

import SwiftUI
import PencilKit

// MARK: - Editor Canvas View
struct EditorCanvasView: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        GeometryReader { geometry in
            let displaySize = calculateImageSize(
                imageSize: viewModel.originalImage.size,
                containerSize: geometry.size
            )
            let scaleX = viewModel.originalImage.size.width / displaySize.width
            let scaleY = viewModel.originalImage.size.height / displaySize.height
            let offsetX = (geometry.size.width - displaySize.width) / 2
            let offsetY = (geometry.size.height - displaySize.height) / 2

            ZStack {
                // 灰色背景（编辑区域外）
                Color(.systemGray5)
                    .ignoresSafeArea()

                // 背景图片
                Image(uiImage: viewModel.originalImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 点击空白区域：取消所有工具和文本选中
                        viewModel.deselectAllTools()
                    }

                // Canvas 绘画层
                CanvasView(canvasView: viewModel.canvasView, viewModel: viewModel)
                    .frame(width: displaySize.width, height: displaySize.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                // 文本叠加层
                textOverlaysView(
                    scaleX: scaleX,
                    scaleY: scaleY,
                    offsetX: offsetX,
                    offsetY: offsetY,
                    displaySize: displaySize
                )
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }

    @ViewBuilder
    private func textOverlaysView(
        scaleX: CGFloat,
        scaleY: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        displaySize: CGSize
    ) -> some View {
        ForEach(viewModel.textOverlays) { overlay in
            let screenPosition = CGPoint(
                x: overlay.position.x / scaleX + offsetX,
                y: overlay.position.y / scaleY + offsetY
            )
            let displayFontSize = overlay.fontSize / scaleX

            DraggableTextView(
                overlay: overlay,
                displayPosition: screenPosition,
                displayFontSize: displayFontSize,
                imageSize: displaySize,
                imageOffset: CGPoint(x: offsetX, y: offsetY),
                isSelected: viewModel.selectedOverlayId == overlay.id,
                onTap: {
                    viewModel.selectedOverlayId = overlay.id
                    // 选中文本时，切换到文本工具
                    viewModel.currentTool = .text
                },
                onDrag: { screenPos in
                    let imagePosition = CGPoint(
                        x: (screenPos.x - offsetX) * scaleX,
                        y: (screenPos.y - offsetY) * scaleY
                    )
                    viewModel.updateTextOverlay(overlay.id, position: imagePosition)
                }
            )
        }
    }

    private func calculateImageSize(imageSize: CGSize, containerSize: CGSize) -> CGSize {
        let aspectRatio = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height

        if aspectRatio > containerAspect {
            // 图片更宽
            let width = containerSize.width
            let height = width / aspectRatio
            return CGSize(width: width, height: height)
        } else {
            // 图片更高
            let height = containerSize.height
            let width = height * aspectRatio
            return CGSize(width: width, height: height)
        }
    }
}

// MARK: - Canvas View (UIViewRepresentable)
struct CanvasView: UIViewRepresentable {
    let canvasView: PKCanvasView
    @ObservedObject var viewModel: EditorViewModel

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = context.coordinator

        // 允许手指和Apple Pencil绘画
        canvasView.drawingPolicy = .anyInput

        // 启用用户交互
        canvasView.isUserInteractionEnabled = true

        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 更新工具
        uiView.tool = canvasView.tool
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let viewModel: EditorViewModel

        init(viewModel: EditorViewModel) {
            self.viewModel = viewModel
        }
    }
}
