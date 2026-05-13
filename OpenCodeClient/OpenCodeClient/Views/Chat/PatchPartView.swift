//
//  PatchPartView.swift
//  OpenCodeClient
//

import SwiftUI

struct PatchPartView: View {
    @Environment(\.colorScheme) private var colorScheme
    let part: Part
    let workspaceDirectory: String?
    let onOpenResolvedPath: (String) -> Void
    let onOpenFilesTab: () -> Void
    @State private var showOpenFileSheet = false

    var body: some View {
        let fileCount = part.files?.count ?? 0
        let accent = DesignColors.Semantic.warning
        Button {
            let paths = part.filePathsForNavigation
            if paths.count == 1 {
                openFile(paths[0])
            } else if paths.count > 1 {
                showOpenFileSheet = true
            } else {
                onOpenFilesTab()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(accent)
                Text(L10n.patchFilesChanged(fileCount))
                    .fontWeight(.medium)
                    .foregroundStyle(accent)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(DesignTypography.micro)
                    .foregroundStyle(.tertiary)
            }
            .font(DesignTypography.micro)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSpacing.cardPadding)
            .background(accent.opacity(DesignColors.surfaceFill(for: colorScheme)))
            .clipShape(RoundedRectangle(cornerRadius: DesignCorners.medium))
        }
        .buttonStyle(.plain)
        .confirmationDialog(L10n.t(.toolOpenFile), isPresented: $showOpenFileSheet) {
            ForEach(part.filePathsForNavigation, id: \.self) { path in
                Button(L10n.toolOpenFileLabel(path: path)) {
                    openFile(path)
                }
            }
            Button(L10n.t(.commonCancel), role: .cancel) {}
        } message: {
            Text(L10n.t(.toolSelectFile))
        }
    }

    private func openFile(_ path: String) {
        let raw = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = PathNormalizer.resolveWorkspaceRelativePath(raw, workspaceDirectory: workspaceDirectory)
        guard !p.isEmpty else { return }
        onOpenResolvedPath(p)
    }
}
