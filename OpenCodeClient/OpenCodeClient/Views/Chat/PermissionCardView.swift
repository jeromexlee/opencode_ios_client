//
//  PermissionCardView.swift
//  OpenCodeClient
//

import SwiftUI

struct PermissionCardView: View {
    @Environment(\.colorScheme) private var colorScheme
    let permission: PendingPermission
    let onRespond: (APIClient.PermissionResponse) -> Void

    private let accent = DesignColors.Semantic.warning

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(accent)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundStyle(accent)
                        .font(.title3)
                    Text(L10n.t(.permissionRequired))
                        .font(DesignTypography.headline.weight(.semibold))
                        .foregroundStyle(accent)
                }

                if let name = permission.permission, !name.isEmpty {
                    Text(name)
                        .font(DesignTypography.body.weight(.semibold))
                }

                Text(permission.description)
                    .font(DesignTypography.body)
                    .foregroundStyle(.secondary)

                if !permission.patterns.isEmpty {
                    Text(permission.patterns.joined(separator: ", "))
                        .font(DesignTypography.micro)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Button {
                            onRespond(.once)
                        } label: {
                            Text(L10n.t(.permissionAllowOnce))
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button {
                            onRespond(.always)
                        } label: {
                            Text(L10n.t(.permissionAllowAlways))
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        .disabled(!permission.allowAlways)
                    }

                    Button {
                        onRespond(.reject)
                    } label: {
                        Text(L10n.t(.permissionReject))
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
            .padding(DesignSpacing.cardPadding)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.opacity(DesignColors.surfaceFill(for: colorScheme)))
        .clipShape(RoundedRectangle(cornerRadius: DesignCorners.medium))
    }
}
