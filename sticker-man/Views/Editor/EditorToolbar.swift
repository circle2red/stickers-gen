//
//  EditorToolbar.swift
//  stickers-gen
//
//  Created on 2025/12/26.
//

import SwiftUI

// MARK: - Editor Toolbar
struct EditorToolbar: View {
    @ObservedObject var viewModel: EditorViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                // 左侧工具选择
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
                        icon: "abc",
                        isSelected: viewModel.currentTool == .text,
                        action: { viewModel.selectTool(.text) }
                    )

                    // 删除选中的文本按钮
                    if viewModel.selectedOverlayId != nil {
                        Button(action: {
                            if let selectedId = viewModel.selectedOverlayId {
                                viewModel.deleteTextOverlay(selectedId)
                            }
                        }) {
                            Image(systemName: "trash")
                                .font(.title3)
                                .foregroundColor(.red)
                                .frame(width: 44, height: 44)
                        }
                    }
                }

                Spacer()

                // 右侧白边按钮
                Button(action: {
                    viewModel.toggleBottomPadding()
                }) {
                    Image(systemName: "rectangle.bottomthird.inset.filled")
                        .font(.title3)
                        .foregroundColor(viewModel.hasBottomPadding ? .white : .primary)
                        .frame(width: 44, height: 44)
                        .background(viewModel.hasBottomPadding ? Color.blue : Color.clear)
                        .cornerRadius(8)
                }
            }

            // 画笔工具选项
            if viewModel.currentTool == .brush {
                BrushOptionsView(viewModel: viewModel)
            }

            // 文本编辑选项（当有选中的文本时显示）
            if let selectedId = viewModel.selectedOverlayId,
               let overlay = viewModel.textOverlays.first(where: { $0.id == selectedId }) {
                TextEditOptionsView(viewModel: viewModel, overlay: overlay)
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

            // 粗细滑块
            HStack {
                Text("粗细")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Slider(value: $viewModel.brushWidth, in: 2...32, step: 7.5) {
                    Text("粗细")
                } minimumValueLabel: {
                    Text("细")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("粗")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .onChange(of: viewModel.brushWidth) { _, newValue in
                    viewModel.updateBrushWidth(newValue)
                }
                .frame(maxWidth: 200)
            }
        }
    }
}

// MARK: - Text Edit Options View
struct TextEditOptionsView: View {
    @ObservedObject var viewModel: EditorViewModel
    let overlay: TextOverlay

    var body: some View {
        VStack(spacing: 8) {
            // 字体大小
            HStack {
                Text("大小")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Slider(value: Binding(
                    get: { overlay.fontSize },
                    set: { newValue in
                        viewModel.updateTextOverlay(overlay.id, fontSize: newValue)
                    }
                ), in: 16...80, step: 4) {
                    Text("大小")
                } minimumValueLabel: {
                    Text("小")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } maximumValueLabel: {
                    Text("大")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: 200)

                Text("\(Int(overlay.fontSize))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30)
            }

            // 颜色选择
            HStack {
                Text("颜色")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    viewModel.showTextColorPicker = true
                }) {
                    Circle()
                        .fill(overlay.color)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Circle()
                                .stroke(Color.gray, lineWidth: 1)
                        )
                }
            }
        }
    }
}
