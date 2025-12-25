//
//  EditorSheets.swift
//  stickers-gen
//
//  Created on 2025/12/26.
//

import SwiftUI

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
