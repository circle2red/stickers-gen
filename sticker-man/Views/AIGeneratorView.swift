//
//  AIGeneratorView.swift
//  stickers-gen
//
//  Created on 2025/12/30.
//

import SwiftUI
import PhotosUI

/// AI创作视图
struct AIGeneratorView: View {
    @StateObject private var viewModel = AIGeneratorViewModel()
    @State private var showingSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题和配置按钮
                headerSection

                // 基础图片选择区域
                imageSelectionSection

                // Prompt输入区域
                promptInputSection

                // 生成按钮
                generateButton

                // 生成的图片显示区域
                if viewModel.hasGeneratedImage {
                    generatedImageSection
                }
            }
            .padding()
        }
        .navigationTitle("AI创作")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                AIConfigDetailView(viewModel: SettingsViewModel())
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
        .alert("保存成功", isPresented: $viewModel.showSuccessAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("AI生成的表情包已保存到图库")
        }
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task {
                await viewModel.loadSelectedImage()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 50))
                .foregroundColor(.purple)

            Text("使用AI创作表情包")
                .font(.headline)
                .foregroundColor(.secondary)

            if !viewModel.aiConfig.isValid {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("请先配置AI设置")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Button("去设置") {
                        showingSettings = true
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Image Selection Section
    private var imageSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("基础图片（可选）")
                    .font(.headline)

                Spacer()

                if viewModel.selectedImage != nil {
                    Button("清除") {
                        viewModel.clearSelectedImage()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }

            if let selectedImage = viewModel.selectedImage {
                // 显示选中的图片
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                // 选择图片按钮
                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("选择图片")
                                .font(.body)
                                .fontWeight(.medium)

                            Text("从相册中选择一张图片作为基础")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }

            Text("提示：选择基础图片后，AI会根据提示词对图片进行修改")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Prompt Input Section
    private var promptInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("描述提示词")
                .font(.headline)

            TextEditor(text: $viewModel.prompt)
                .frame(minHeight: 120)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if viewModel.prompt.isEmpty {
                        Text("例如：（给定参考图），将人物的头发改成紫色……或（未给定参考图）生成一个微笑表情包……")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }

            Text("提示：详细描述你想要的效果，AI会根据描述生成图片")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Generate Button
    private var generateButton: some View {
        Button {
            Task {
                await viewModel.generateImage()
            }
        } label: {
            HStack(spacing: 12) {
                if viewModel.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "sparkles")
                }

                Text(viewModel.isGenerating ? "生成中..." : "开始生成")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                viewModel.canGenerate
                    ? Color.purple
                    : Color.gray.opacity(0.3)
            )
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(!viewModel.canGenerate)
    }

    // MARK: - Generated Image Section
    private var generatedImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("生成结果")
                    .font(.headline)

                Spacer()

                Button("清除") {
                    viewModel.clearGeneratedImage()
                }
                .font(.caption)
                .foregroundColor(.red)
            }

            if let generatedImage = viewModel.generatedImage {
                Image(uiImage: generatedImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                    )

                // 保存按钮
                Button {
                    Task {
                        await viewModel.saveGeneratedImage()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "square.and.arrow.down")

                        Text("保存为表情包")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 12)
    }
}

#Preview {
    NavigationStack {
        AIGeneratorView()
    }
}
