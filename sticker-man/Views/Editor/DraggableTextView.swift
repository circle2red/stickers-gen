//
//  DraggableTextView.swift
//  stickers-gen
//
//  Created on 2025/12/26.
//

import SwiftUI

// MARK: - Draggable Text View
struct DraggableTextView: View {
    let overlay: TextOverlay
    let displayPosition: CGPoint // 屏幕坐标
    let displayFontSize: CGFloat // 屏幕显示的字体大小（已缩放）
    let imageSize: CGSize // 图片在屏幕上的显示尺寸
    let imageOffset: CGPoint // 图片在屏幕上的偏移
    let isSelected: Bool
    let onTap: () -> Void
    let onDrag: (CGPoint) -> Void // 传递屏幕坐标

    @State private var dragOffset: CGSize = .zero
    @State private var textSize: CGSize = .zero

    var body: some View {
        Text(overlay.text)
            .font(.system(size: displayFontSize, weight: .bold))
            .foregroundColor(overlay.color)
            .shadow(color: .black, radius: 2, x: 0, y: 0)
            .shadow(color: .black, radius: 2, x: 0, y: 0)
            .padding(8)
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(key: TextSizePreferenceKey.self, value: geometry.size)
                }
            )
            .onPreferenceChange(TextSizePreferenceKey.self) { size in
                textSize = size
            }
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
                        // 计算新位置（屏幕坐标）
                        var newX = displayPosition.x + value.translation.width
                        var newY = displayPosition.y + value.translation.height

                        // 限制在图片边界内，考虑文本框的实际尺寸
                        let halfWidth = textSize.width / 2
                        let halfHeight = textSize.height / 2

                        let minX = imageOffset.x + halfWidth
                        let maxX = imageOffset.x + imageSize.width - halfWidth
                        let minY = imageOffset.y + halfHeight
                        let maxY = imageOffset.y + imageSize.height - halfHeight

                        newX = max(minX, min(maxX, newX))
                        newY = max(minY, min(maxY, newY))

                        let newScreenPosition = CGPoint(x: newX, y: newY)
                        onDrag(newScreenPosition)
                        dragOffset = .zero
                    }
            )
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Text Size Preference Key
private struct TextSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
