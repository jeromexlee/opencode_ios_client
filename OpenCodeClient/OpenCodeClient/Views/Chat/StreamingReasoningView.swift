//
//  StreamingReasoningView.swift
//  OpenCodeClient
//

import SwiftUI

/// 仅在 streaming 时显示，think 完成后消失。无 sync 栏，灰色字体打字机效果。
@MainActor
struct StreamingReasoningView: View {
    let part: Part
    @Bindable var state: AppState

    private var displayText: String {
        let key = "\(part.messageID):\(part.id)"
        return state.streamingPartTexts[key] ?? part.text ?? ""
    }

    var body: some View {
        if !displayText.isEmpty {
            Text(displayText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
