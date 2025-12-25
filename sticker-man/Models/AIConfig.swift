//
//  AIConfig.swift
//  stickers-gen
//
//  Created on 2025/12/22.
//

import Foundation

/// AI配置数据模型
struct AIConfig: Codable {
    var apiEndpoint: String
    var apiKey: String
    var modelName: String
    var temperature: Double
    var maxTokens: Int

    init(
        apiEndpoint: String = Constants.AI.defaultEndpoint,
        apiKey: String = "",
        modelName: String = Constants.AI.defaultModelName,
        temperature: Double = Constants.AI.defaultTemperature,
        maxTokens: Int = Constants.AI.defaultMaxTokens
    ) {
        self.apiEndpoint = apiEndpoint
        self.apiKey = apiKey
        self.modelName = modelName
        self.temperature = temperature
        self.maxTokens = maxTokens
    }

    // MARK: - UserDefaults Storage
    /// 从UserDefaults加载配置
    static func load() -> AIConfig {
        let defaults = UserDefaults.standard
        return AIConfig(
            apiEndpoint: defaults.string(forKey: Constants.UserDefaultsKeys.apiEndpoint) ?? Constants.AI.defaultEndpoint,
            apiKey: defaults.string(forKey: Constants.UserDefaultsKeys.apiKey) ?? "",
            modelName: defaults.string(forKey: Constants.UserDefaultsKeys.modelName) ?? Constants.AI.defaultModelName,
            temperature: defaults.double(forKey: Constants.UserDefaultsKeys.temperature) != 0
                ? defaults.double(forKey: Constants.UserDefaultsKeys.temperature)
                : Constants.AI.defaultTemperature,
            maxTokens: defaults.integer(forKey: Constants.UserDefaultsKeys.maxTokens) != 0
                ? defaults.integer(forKey: Constants.UserDefaultsKeys.maxTokens)
                : Constants.AI.defaultMaxTokens
        )
    }

    /// 保存配置到UserDefaults
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(apiEndpoint, forKey: Constants.UserDefaultsKeys.apiEndpoint)
        defaults.set(apiKey, forKey: Constants.UserDefaultsKeys.apiKey)
        defaults.set(modelName, forKey: Constants.UserDefaultsKeys.modelName)
        defaults.set(temperature, forKey: Constants.UserDefaultsKeys.temperature)
        defaults.set(maxTokens, forKey: Constants.UserDefaultsKeys.maxTokens)
    }

    /// 清除配置
    static func clear() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.apiEndpoint)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.apiKey)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.modelName)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.temperature)
        defaults.removeObject(forKey: Constants.UserDefaultsKeys.maxTokens)
    }

    /// 检查配置是否完整
    var isValid: Bool {
        return !apiEndpoint.isEmpty && !apiKey.isEmpty && !modelName.isEmpty
    }
}
