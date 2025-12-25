//
//  TagEditorView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// 标签编辑视图
struct TagEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var tags: [String]
    let allTags: [String]  // 所有可用标签（用于建议）

    @State private var newTag: String = ""
    @State private var showingSuggestions: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 标签输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("添加标签")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack {
                        TextField("输入标签名称...", text: $newTag)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addTag()
                            }

                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newTag.isEmpty)
                    }
                    .padding(.horizontal)

                    // 标签建议
                    if !newTag.isEmpty && !filteredSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(filteredSuggestions, id: \.self) { suggestion in
                                    Button(action: {
                                        newTag = suggestion
                                        addTag()
                                    }) {
                                        Text(suggestion)
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)

                Divider()

                // 已添加的标签
                VStack(alignment: .leading, spacing: 8) {
                    Text("已添加的标签 (\(tags.count))")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top)

                    if tags.isEmpty {
                        Text("还没有添加任何标签")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack {
                                        Image(systemName: "tag.fill")
                                            .foregroundColor(.blue)
                                            .font(.caption)

                                        Text(tag)
                                            .font(.body)

                                        Spacer()

                                        Button(action: {
                                            removeTag(tag)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helper Methods
    private var filteredSuggestions: [String] {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return []
        }

        return allTags
            .filter { $0.localizedCaseInsensitiveContains(trimmed) }
            .filter { !tags.contains($0) }
            .prefix(5)
            .map { $0 }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !tags.contains(trimmed) else {
            newTag = ""
            return
        }

        tags.append(trimmed)
        newTag = ""
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}

#Preview {
    TagEditorView(
        tags: .constant(["搞笑", "表情包"]),
        allTags: ["搞笑", "表情包", "可爱", "萌宠", "猫咪", "狗狗"]
    )
}
