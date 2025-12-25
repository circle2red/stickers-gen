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
            .sheet(isPresented: $viewModel.showTextColorPicker) {
                ColorPickerSheet(selectedColor: $viewModel.textColor, onSelect: { color in
                    viewModel.updateTextColor(color)
                })
            }
        }
    }
}

#Preview {
    EditorView(image: UIImage(systemName: "photo")!)
}
