//
//  HomeView.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import SwiftUI

/// 主视图（带侧边栏菜单）
struct HomeView: View {
    @State private var selectedSection: MenuSection = .library
    @State private var showingSideMenu = false

    var body: some View {
        ZStack {
            NavigationStack {
                // 根据选中的菜单显示不同内容
                contentView
                    .navigationTitle(selectedSection.rawValue)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            // 汉堡菜单按钮
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSideMenu.toggle()
                                }
                            }) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.title3)
                            }
                        }
                    }
            }

            // 侧边栏菜单
            SideMenuView(
                selectedSection: $selectedSection,
                isShowing: $showingSideMenu
            )
        }
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch selectedSection {
        case .library:
            StickerLibraryView()
        case .editor:
            EditorPlaceholderView()
        case .ai:
            AIGeneratorPlaceholderView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    HomeView()
}
