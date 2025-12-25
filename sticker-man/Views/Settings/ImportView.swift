//
//  ImportView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// 导入视图
struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ImportViewModel()

    // Photo Picker
    @State private var selectedPhotoItems: [PhotosPickerItem] = []

    // Document Picker
    @State private var showingDocumentPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isImporting {
                    // 导入进度视图
                    ImportProgressView(
                        progress: viewModel.importProgress,
                        importedCount: viewModel.importedCount,
                        totalCount: viewModel.totalCount,
                        currentFileName: viewModel.currentFileName
                    )
                } else {
                    // 导入选项
                    importOptionsView
                }
            }
            .navigationTitle("导入表情包")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
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
            .onChange(of: selectedPhotoItems) { oldValue, newValue in
                if !newValue.isEmpty {
                    Task {
                        await viewModel.importPhotos(newValue)
                        selectedPhotoItems = []

                        // 导入完成后关闭
                        if !viewModel.showError {
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker { urls in
                    Task {
                        await viewModel.importDocuments(urls)

                        // 导入完成后关闭
                        if !viewModel.showError {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Import Options View
    private var importOptionsView: some View {
        VStack(spacing: 24) {
            Spacer()

            // 标题
            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("选择导入方式")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("支持JPG、PNG、GIF格式")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)

            // 导入按钮
            VStack(spacing: 16) {
                // 从相册导入
                PhotosPicker(
                    selection: $selectedPhotoItems,
                    maxSelectionCount: 50,
                    matching: .images
                ) {
                    ImportOptionButton(
                        icon: "photo.on.rectangle",
                        title: "从相册导入",
                        subtitle: "支持多选，最多50张"
                    )
                }

                // 从文件导入
                Button {
                    showingDocumentPicker = true
                } label: {
                    ImportOptionButton(
                        icon: "folder",
                        title: "从文件导入",
                        subtitle: "支持图片和ZIP压缩包"
                    )
                }

                // 提示信息
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                        .font(.caption)

                    Text("图片将自动压缩至200KB以下")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

// MARK: - Import Option Button
struct ImportOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Import Progress View
struct ImportProgressView: View {
    let progress: Double
    let importedCount: Int
    let totalCount: Int
    let currentFileName: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 进度环
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: progress)

                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("\(importedCount)/\(totalCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 状态文本
            VStack(spacing: 8) {
                Text("正在导入...")
                    .font(.headline)

                Text(currentFileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 250)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: [
                .image,
                .jpeg,
                .png,
                .gif,
                .zip
            ],
            asCopy: true
        )
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: ([URL]) -> Void

        init(onPick: @escaping ([URL]) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls)
        }
    }
}

#Preview {
    ImportView()
}
