//
//  CreateNewStickerView.swift
//  stickers-gen
//
//  Created on 2025/12/25.
//

import SwiftUI


/// 新建表情包视图
struct CreateNewStickerView: View {
    @State private var selectedSize: CanvasSize = .square512
    @State private var customWidth: String = "512"
    @State private var customHeight: String = "512"
    @State private var editorImage: IdentifiableImage?

    var body: some View {
        VStack(spacing: 30) {
            // 标题
            VStack(spacing: 10) {
                Image(systemName: "plus.square")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("新建表情包")
                    .font(.title)
                    .fontWeight(.bold)

                Text("选择画布大小并开始创作")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            // 预设尺寸选择
            VStack(alignment: .leading, spacing: 15) {
                Text("预设尺寸")
                    .font(.headline)
                    .foregroundColor(.primary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(CanvasSize.allCases, id: \.self) { size in
                        SizeButton(
                            size: size,
                            isSelected: selectedSize == size,
                            action: {
                                selectedSize = size
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)

            // 自定义尺寸
            if selectedSize == .custom {
                VStack(alignment: .leading, spacing: 15) {
                    Text("自定义尺寸")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("宽度")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("宽度", text: $customWidth)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("高度")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            TextField("高度", text: $customHeight)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()

            // 创建按钮
            Button(action: {
                createBlankImage()
            }) {
                Text("开始创作")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .fullScreenCover(item: $editorImage) { identifiableImage in
            EditorView(image: identifiableImage.image)
        }
    }

    private func createBlankImage() {
        let size = selectedSize.size(customWidth: customWidth, customHeight: customHeight)
        if let image = createBlankCanvas(size: size) {
            editorImage = IdentifiableImage(image: image)
        }
    }

    private func createBlankCanvas(size: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            // 填充白色背景
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Canvas Size
enum CanvasSize: String, CaseIterable {
    case square512 = "512x512"
    case banner = "512x1080"
    case custom = "自定义"

    var displayName: String {
        rawValue
    }

    var description: String {
        switch self {
        case .square512:
            return "标准方形"
        case .banner:
            return "横幅表情"
        case .custom:
            return "自定义尺寸"
        }
    }

    func size(customWidth: String = "512", customHeight: String = "512") -> CGSize {
        switch self {
        case .square512:
            return CGSize(width: 512, height: 512)
        case .banner:
            return CGSize(width: 512, height: 1080)
        case .custom:
            let width = CGFloat(Int(customWidth) ?? 512)
            let height = CGFloat(Int(customHeight) ?? 512)
            return CGSize(width: max(100, min(4096, width)), height: max(100, min(4096, height)))
        }
    }
}

// MARK: - Size Button
struct SizeButton: View {
    let size: CanvasSize
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: size == .custom ? "square.dashed" : "square")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)

                Text(size.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                Text(size.description)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

#Preview {
    CreateNewStickerView()
}
