//
//  AIConfigDetailView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// AI配置详情视图
struct AIConfigDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: SettingsViewModel

    @State private var apiEndpoint: String = ""
    @State private var apiKey: String = ""
    @State private var modelName: String = ""
    @State private var temperature: Double = 0.7
    @State private var maxTokens: Int = 1024

    @State private var isTestingConnection = false
    @State private var showTestSuccess = false
    @State private var hasChanges = false

    var body: some View {
        Form {
            // API配置
            Section {
                TextField("API端点", text: $apiEndpoint)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .onChange(of: apiEndpoint) { _, _ in
                        hasChanges = true
                    }

                SecureField("API Key", text: $apiKey)
                    .textContentType(.password)
                    .onChange(of: apiKey) { _, _ in
                        hasChanges = true
                    }

                TextField("模型名称", text: $modelName)
                    .autocapitalization(.none)
                    .onChange(of: modelName) { _, _ in
                        hasChanges = true
                    }
            } header: {
                Text("基础配置")
            } footer: {
                Text("请填写AI服务商提供的API信息")
            }

            // 高级配置
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(String(format: "%.1f", temperature))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $temperature, in: 0...2, step: 0.1)
                        .onChange(of: temperature) { _, _ in
                            hasChanges = true
                        }
                }

                HStack {
                    Text("Max Tokens")

                    Spacer()

                    TextField("", value: $maxTokens, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .onChange(of: maxTokens) { _, _ in
                            hasChanges = true
                        }
                }
            } header: {
                Text("高级配置")
            } footer: {
                Text("Temperature控制生成的随机性，Max Tokens限制生成内容的长度")
            }

            // 预设配置
            Section("快速配置") {
                Button {
                    loadGeminiPreset()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gemini 3 Pro")
                                .foregroundColor(.primary)

                            Text("Google的最新AI模型")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Button {
                    loadOpenAIPreset()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OpenAI DALL-E")
                                .foregroundColor(.primary)

                            Text("OpenAI的图像生成模型")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }

            // 测试和保存
            Section {
                Button {
                    testConnection()
                } label: {
                    HStack {
                        if isTestingConnection {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "checkmark.circle")
                        }

                        Text("测试连接")
                    }
                }
                .disabled(isTestingConnection || !isConfigValid)

                Button {
                    saveConfig()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("保存配置")
                    }
                }
                .fontWeight(.semibold)
                .disabled(!hasChanges)
            }
        }
        .navigationTitle("AI配置")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadConfig()
        }
        .alert("连接成功", isPresented: $showTestSuccess) {
            Button("确定", role: .cancel) {}
        } message: {
            Text("API连接测试成功！")
        }
    }

    // MARK: - Computed Properties
    private var isConfigValid: Bool {
        !apiEndpoint.isEmpty && !apiKey.isEmpty && !modelName.isEmpty
    }

    // MARK: - Methods
    private func loadConfig() {
        let config = viewModel.aiConfig
        apiEndpoint = config.apiEndpoint
        apiKey = config.apiKey
        modelName = config.modelName
        temperature = config.temperature
        maxTokens = config.maxTokens
        hasChanges = false
    }

    private func saveConfig() {
        viewModel.aiConfig = AIConfig(
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName,
            temperature: temperature,
            maxTokens: maxTokens
        )
        viewModel.saveAIConfig()
        hasChanges = false
    }

    private func testConnection() {
        isTestingConnection = true

        Task {
            // 先保存当前配置
            saveConfig()

            let success = await viewModel.testAIConnection()

            isTestingConnection = false

            if success {
                showTestSuccess = true
            }
        }
    }

    private func loadGeminiPreset() {
        apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models"
        modelName = "gemini-3-pro"
        temperature = 0.7
        maxTokens = 1024
        hasChanges = true
    }

    private func loadOpenAIPreset() {
        apiEndpoint = "https://api.openai.com/v1/images/generations"
        modelName = "dall-e-3"
        temperature = 0.7
        maxTokens = 1024
        hasChanges = true
    }
}

#Preview {
    NavigationStack {
        AIConfigDetailView(viewModel: SettingsViewModel())
    }
}
