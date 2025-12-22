//
//  SideMenuView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// 侧边栏菜单项
enum MenuSection: String, CaseIterable, Identifiable {
    case library = "表情包图库"
    case editor = "编辑"
    case ai = "AI创作"
    case settings = "设置"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .library:
            return "photo.on.rectangle.angled"
        case .editor:
            return "pencil.and.outline"
        case .ai:
            return "wand.and.stars"
        case .settings:
            return "gear"
        }
    }
}

/// 侧边栏菜单视图
struct SideMenuView: View {
    @Binding var selectedSection: MenuSection
    @Binding var isShowing: Bool

    var body: some View {
        ZStack {
            // 背景遮罩
            if isShowing {
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isShowing = false
                        }
                    }
            }

            // 侧边栏内容
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // 头部
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "face.smiling.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Sticker-Gen")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("表情包管理工具")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 30)

                    Divider()

                    // 菜单项
                    VStack(spacing: 0) {
                        ForEach(MenuSection.allCases) { section in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedSection = section
                                    isShowing = false
                                }
                            }) {
                                HStack(spacing: 15) {
                                    Image(systemName: section.icon)
                                        .font(.title3)
                                        .foregroundColor(selectedSection == section ? .blue : .primary)
                                        .frame(width: 30)

                                    Text(section.rawValue)
                                        .font(.body)
                                        .foregroundColor(selectedSection == section ? .blue : .primary)

                                    Spacer()

                                    if selectedSection == section {
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(
                                    selectedSection == section
                                        ? Color.blue.opacity(0.1)
                                        : Color.clear
                                )
                            }

                            if section != MenuSection.allCases.last {
                                Divider()
                                    .padding(.leading, 20)
                            }
                        }
                    }
                    .padding(.top, 10)

                    Spacer()

                    // 底部信息
                    VStack(spacing: 4) {
                        Text("Version 1.0.0")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text("© 2025 Sticker-Gen")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 30)
                }
                .frame(width: 280)
                .background(Color(.systemBackground))
                .offset(x: isShowing ? 0 : -280)

                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowing)
    }
}

#Preview {
    SideMenuView(
        selectedSection: .constant(.library),
        isShowing: .constant(true)
    )
}
