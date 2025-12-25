//
//  sticker_manApp.swift
//  sticker man
//
//  Created by Chmm on 2025/12/22.
//

import SwiftUI

@main
struct sticker_manApp: App {
    init() {
        // 初始化服务
        setupServices()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }

    // MARK: - Setup Services
    private func setupServices() {
        // 初始化数据库
        Task {
            await DatabaseManager.shared.initialize()
        }

        // 初始化文件存储（在init中已自动初始化）
        _ = FileStorageManager.shared

        print("✅ Sticker Man App initialized")
    }
}
