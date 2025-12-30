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

            // 快速配置
            Section("快速配置") {
                Button {
                    loadOpenRouterPreset()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OpenRouter")
                                .foregroundColor(.primary)

                            Text("通过OpenRouter使用Google Gemini图像生成")
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
                    loadVercelPreset()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Vercel AI Gateway")
                                .foregroundColor(.primary)

                            Text("通过Vercel AI网关访问AI服务")
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
        hasChanges = false
    }

    private func saveConfig() {
        viewModel.aiConfig = AIConfig(
            apiEndpoint: apiEndpoint,
            apiKey: apiKey,
            modelName: modelName
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

    private func loadOpenRouterPreset() {
        apiEndpoint = "https://openrouter.ai/api/v1/chat/completions"
        modelName = "google/gemini-2.5-flash-image"
        hasChanges = true
    }

    private func loadVercelPreset() {
        apiEndpoint = "https://ai-gateway.vercel.sh/v1/chat/completions"
        modelName = "google/gemini-2.5-flash-image"
        hasChanges = true
    }
}

#Preview {
    NavigationStack {
        AIConfigDetailView(viewModel: SettingsViewModel())
    }
}
