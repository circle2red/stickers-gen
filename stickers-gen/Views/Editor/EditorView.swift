//
//  EditorView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI
import PencilKit

/// 图片编辑器视图
struct EditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: EditorViewModel

    init(image: UIImage, sticker: Sticker? = nil) {
        _viewModel = StateObject(wrappedValue: EditorViewModel(image: image, sticker: sticker))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 主编辑区域
                EditorCanvasView(viewModel: viewModel)

                // 工具栏
                VStack {
                    Spacer()

                    EditorToolbar(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        Task {
                            let success = await viewModel.save()
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .fontWeight(.semibold)
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
            .sheet(isPresented: $viewModel.showColorPicker) {
                ColorPickerSheet(selectedColor: $viewModel.brushColor, onSelect: { color in
                    viewModel.updateBrushColor(color)
                })
            }
            .sheet(isPresented: $viewModel.showTextEditor) {
                TextEditorSheet(onAdd: { text in
                    viewModel.addTextOverlay(text)
                })
            }
            .fullScreenCover(isPresented: $viewModel.isCropping) {
                CropView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Editor Canvas View
struct EditorCanvasView: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        GeometryReader { geometry in
            // 计算图片的实际显示尺寸
            let displaySize = calculateImageSize(
                imageSize: viewModel.originalImage.size,
                containerSize: geometry.size
            )

            // 计算图片坐标和屏幕坐标的缩放比例
            let scaleX = viewModel.originalImage.size.width / displaySize.width
            let scaleY = viewModel.originalImage.size.height / displaySize.height

            // 计算图片在容器中的偏移（用于居中）
            let offsetX = (geometry.size.width - displaySize.width) / 2
            let offsetY = (geometry.size.height - displaySize.height) / 2

            ZStack {
                // 背景图片
                Image(uiImage: viewModel.originalImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Canvas 绘画层 - 使用相同的尺寸
                CanvasView(canvasView: viewModel.canvasView, viewModel: viewModel)
                    .frame(width: displaySize.width, height: displaySize.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                // 文本叠加层
                ForEach(viewModel.textOverlays) { overlay in
                    // 将图片坐标转换为屏幕坐标显示
                    let screenPosition = CGPoint(
                        x: overlay.position.x / scaleX + offsetX,
                        y: overlay.position.y / scaleY + offsetY
                    )

                    DraggableTextView(
                        overlay: overlay,
                        displayPosition: screenPosition,
                        isSelected: viewModel.selectedOverlayId == overlay.id,
                        onTap: {
                            viewModel.selectedOverlayId = overlay.id
                        },
                        onDrag: { screenPos in
                            // 将屏幕坐标转换为图片坐标
                            let imagePosition = CGPoint(
                                x: (screenPos.x - offsetX) * scaleX,
                                y: (screenPos.y - offsetY) * scaleY
                            )
                            viewModel.updateTextOverlay(overlay.id, position: imagePosition)
                        }
                    )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
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

        // 只在绘画结束时保存状态（用户抬起手指/笔）
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            Task { @MainActor in
                viewModel.saveDrawingState()
            }
        }
    }
}

// MARK: - Editor Toolbar
struct EditorToolbar: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 12) {
            // 工具选择
            HStack(spacing: 20) {
                ToolButton(
                    icon: "pencil.tip",
                    isSelected: viewModel.currentTool == .brush,
                    action: { viewModel.selectTool(.brush) }
                )

                ToolButton(
                    icon: "eraser.fill",
                    isSelected: viewModel.currentTool == .eraser,
                    action: { viewModel.selectTool(.eraser) }
                )

                ToolButton(
                    icon: "textformat",
                    isSelected: viewModel.currentTool == .text,
                    action: { viewModel.selectTool(.text) }
                )

                ToolButton(
                    icon: "crop",
                    isSelected: viewModel.currentTool == .crop,
                    action: { viewModel.startCrop() }
                )

                Spacer()

                // 撤销/重做
                Button(action: { viewModel.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title3)
                        .foregroundColor(viewModel.canUndo ? .primary : .gray)
                }
                .disabled(!viewModel.canUndo)

                Button(action: { viewModel.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title3)
                        .foregroundColor(viewModel.canRedo ? .primary : .gray)
                }
                .disabled(!viewModel.canRedo)
            }

            // 画笔工具选项
            if viewModel.currentTool == .brush {
                BrushOptionsView(viewModel: viewModel)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Tool Button
struct ToolButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 44, height: 44)
                .background(isSelected ? Color.blue : Color.clear)
                .cornerRadius(8)
        }
    }
}

// MARK: - Brush Options View
struct BrushOptionsView: View {
    @ObservedObject var viewModel: EditorViewModel

    let brushSizes: [CGFloat] = [2, 4, 8, 16, 32]

    var body: some View {
        VStack(spacing: 8) {
            // 颜色选择
            HStack {
                Text("颜色")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    viewModel.showColorPicker = true
                }) {
                    Circle()
                        .fill(viewModel.brushColor)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
            }

            // 粗细选择
            HStack {
                Text("粗细")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    ForEach(brushSizes, id: \.self) { size in
                        Button(action: {
                            viewModel.updateBrushWidth(size)
                        }) {
                            Circle()
                                .fill(viewModel.brushWidth == size ? Color.blue : Color.gray)
                                .frame(width: size * 1.5, height: size * 1.5)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Color Picker Sheet
struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: Color
    var onSelect: (Color) -> Void

    let presetColors: [Color] = [
        .black, .white, .red, .blue, .green, .yellow, .orange, .purple, .pink, .brown
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 预设颜色
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(presetColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.blue : Color.gray, lineWidth: 3)
                            )
                            .onTapGesture {
                                selectedColor = color
                                onSelect(color)
                            }
                    }
                }
                .padding()

                // 自定义颜色选择器
                ColorPicker("自定义颜色", selection: $selectedColor)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("选择颜色")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onSelect(selectedColor)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Text Editor Sheet
struct TextEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    var onAdd: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("添加文本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加") {
                        if !text.isEmpty {
                            onAdd(text)
                            dismiss()
                        }
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
    }
}

// MARK: - Draggable Text View
struct DraggableTextView: View {
    let overlay: TextOverlay
    let displayPosition: CGPoint // 屏幕坐标
    let isSelected: Bool
    let onTap: () -> Void
    let onDrag: (CGPoint) -> Void // 传递屏幕坐标

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Text(overlay.text)
            .font(.system(size: overlay.fontSize, weight: .bold))
            .foregroundColor(overlay.color)
            .shadow(color: .black, radius: 2, x: 0, y: 0)
            .shadow(color: .black, radius: 2, x: 0, y: 0)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(isSelected ? 0.3 : 0))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .position(
                x: displayPosition.x + dragOffset.width,
                y: displayPosition.y + dragOffset.height
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let newScreenPosition = CGPoint(
                            x: displayPosition.x + value.translation.width,
                            y: displayPosition.y + value.translation.height
                        )
                        onDrag(newScreenPosition)
                        dragOffset = .zero
                    }
            )
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Crop View
struct CropView: View {
    @ObservedObject var viewModel: EditorViewModel
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                // 显示图片
                Image(uiImage: viewModel.originalImage)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                },
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )

                // 提示文本
                VStack {
                    Text("捏合缩放，拖动调整位置")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(.top, 60)

                    Spacer()
                }
            }
            .navigationTitle("裁剪")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        viewModel.cancelCrop()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        applyCropWithTransform()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func applyCropWithTransform() {
        // 简化版本：重置变换后应用裁剪
        // 实际项目中可以使用更复杂的裁剪逻辑
        viewModel.applyCrop()
    }
}

#Preview {
    EditorView(image: UIImage(systemName: "photo")!)
}
