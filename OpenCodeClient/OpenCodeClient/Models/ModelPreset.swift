//
//  ModelPreset.swift
//  OpenCodeClient
//

import Foundation

struct ModelPreset: Codable, Identifiable {
    var id: String { "\(providerID)/\(modelID)" }
    let displayName: String
    let providerID: String
    let modelID: String
    
    var shortName: String {
        switch displayName {
        case let name where name.contains("Opus"): return "Opus"
        case let name where name.contains("Sonnet"): return "Sonnet"
        case let name where name.contains("GLM"): return "GLM"
        case "DeepSeek V4 Flash": return "DS-Flash"
        case "DeepSeek V4 Pro": return "DS-Pro"
        case let name where name.contains("DeepSeek"): return "DeepSeek"
        case let name where name.contains("Gemini"): return "Gemini"
        case let name where name.contains("GPT"): return "GPT"
        default: return displayName
        }
    }
}
