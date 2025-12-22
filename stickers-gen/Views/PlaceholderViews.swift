//
//  EditorPlaceholderView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// 编辑页面占位符
struct EditorPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pencil.and.outline")
                .font(.system(size: 70))
                .foregroundColor(.blue)

            Text("图片编辑器")
                .font(.title)
                .fontWeight(.bold)

            Text("Phase 4 即将实现")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "crop", text: "裁切功能")
                FeatureRow(icon: "paintbrush", text: "绘画工具")
                FeatureRow(icon: "textformat", text: "添加文字")
                FeatureRow(icon: "slider.horizontal.3", text: "图层管理")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
    }
}

/// AI创作页面占位符
struct AIGeneratorPlaceholderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 70))
                .foregroundColor(.purple)

            Text("AI创作")
                .font(.title)
                .fontWeight(.bold)

            Text("Phase 6 即将实现")
                .font(.body)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "photo", text: "基于图片生成")
                FeatureRow(icon: "text.bubble", text: "文字描述生成")
                FeatureRow(icon: "cpu", text: "多种AI模型")
                FeatureRow(icon: "square.grid.3x3", text: "批量生成")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
    }
}

/// 功能行组件
struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.body)

            Spacer()
        }
    }
}

#Preview("Editor") {
    EditorPlaceholderView()
}

#Preview("AI") {
    AIGeneratorPlaceholderView()
}
