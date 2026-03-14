//
//  MessageRowView.swift
//  OpenCodeClient
//

import SwiftUI
import MarkdownUI
#if canImport(UIKit)
import UIKit
#endif

private struct MessagePreviewImage: Identifiable {
    let id: String
    let data: Data
    let filename: String?
}

struct MessageRowView: View {
    let message: MessageWithParts
    let sessionTodos: [TodoItem]
    let workspaceDirectory: String?
    let onOpenResolvedPath: (String) -> Void
    let onOpenFilesTab: () -> Void
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedPreviewImage: MessagePreviewImage?

    private var cardGridColumnCount: Int { sizeClass == .regular ? 3 : 2 }
    private var cardGridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: cardGridColumnCount)
    }

    private enum AssistantBlock: Identifiable {
        case text(Part)
        case cards([Part])

        var id: String {
            switch self {
            case .text(let p):
                return "text-\(p.id)"
            case .cards(let parts):
                let first = parts.first?.id ?? "nil"
                let last = parts.last?.id ?? "nil"
                return "cards-\(first)-\(last)"
            }
        }
    }

    private var assistantBlocks: [AssistantBlock] {
        var blocks: [AssistantBlock] = []
        var buffer: [Part] = []

        func flushBuffer() {
            guard !buffer.isEmpty else { return }
            blocks.append(.cards(buffer))
            buffer.removeAll(keepingCapacity: true)
        }

        for part in message.parts {
            if part.isReasoning { continue }
            if part.isTool || part.isPatch {
                buffer.append(part)
                continue
            }
            if part.isStepStart || part.isStepFinish { continue }
            if part.isText {
                flushBuffer()
                blocks.append(.text(part))
            } else {
                flushBuffer()
            }
        }

        flushBuffer()
        return blocks
    }

    @ViewBuilder
    private func markdownText(_ text: String) -> some View {
        if shouldRenderMarkdown(text) {
            Markdown(text)
                .textSelection(.enabled)
        } else {
            Text(text)
                .textSelection(.enabled)
        }
    }

    private func shouldRenderMarkdown(_ text: String) -> Bool {
        Self.hasMarkdownSyntax(text)
    }

    private var userTextParts: [Part] {
        message.parts.filter {
            $0.isText && !($0.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        }
    }

    private var userImageParts: [Part] {
        message.parts.filter { $0.isImageFile }
    }

    static func hasMarkdownSyntax(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let markdownSignals = [
            "```", "`", "**", "__", "#", "- ", "* ", "+ ", "1. ",
            "[", "](", "> ", "|", "~~"
        ]
        if markdownSignals.contains(where: { trimmed.contains($0) }) {
            return true
        }

        return trimmed.contains("\n\n")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if message.info.isUser {
                Divider()
                    .padding(.vertical, 4)
                userMessageView
            } else {
                assistantMessageView
            }
        }
        .fullScreenCover(item: $selectedPreviewImage) { preview in
            ImagePreviewScreen(preview: preview)
        }
    }

    private var userMessageView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !userImageParts.isEmpty {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(3, max(1, userImageParts.count))),
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(userImageParts, id: \.id) { part in
                        if let data = part.imageData, let uiImage = UIImage(data: data) {
                            Button {
                                selectedPreviewImage = MessagePreviewImage(id: part.id, data: data, filename: part.filename)
                            } label: {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(minHeight: 120, maxHeight: 180)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.accentColor.opacity(0.14), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if !userTextParts.isEmpty {
                ForEach(userTextParts, id: \.id) { part in
                    markdownText(part.text ?? "")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.accentColor.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.accentColor.opacity(0.14), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            if let model = message.info.resolvedModel {
                Text("\(model.providerID)/\(model.modelID)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 4)
            }
        }
    }

    private var assistantMessageView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(assistantBlocks) { block in
                switch block {
                case .text(let part):
                    markdownText(part.text ?? "")
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case .cards(let parts):
                    LazyVGrid(
                        columns: cardGridColumns,
                        alignment: .leading,
                        spacing: 10
                    ) {
                        ForEach(parts, id: \.id) { part in
                            cardView(part)
                        }
                    }
                }
            }
            if let err = message.info.errorMessageForDisplay {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.25), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .textSelection(.enabled)
            }
        }
    }

    @ViewBuilder
    private func cardView(_ part: Part) -> some View {
        if part.isTool {
            ToolPartView(
                part: part,
                sessionTodos: sessionTodos,
                workspaceDirectory: workspaceDirectory,
                onOpenResolvedPath: onOpenResolvedPath
            )
        } else if part.isPatch {
            PatchPartView(
                part: part,
                workspaceDirectory: workspaceDirectory,
                onOpenResolvedPath: onOpenResolvedPath,
                onOpenFilesTab: onOpenFilesTab
            )
        } else {
            EmptyView()
        }
    }
}

private struct ImagePreviewScreen: View {
    let preview: MessagePreviewImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

#if canImport(UIKit)
                if let uiImage = UIImage(data: preview.data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .background(Color.black)
                        .onTapGesture {
                            dismiss()
                        }
                }
#endif
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.t(.appClose)) {
                        dismiss()
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .navigationTitle(preview.filename ?? "")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
