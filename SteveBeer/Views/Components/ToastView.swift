import SwiftUI

struct ToastView: View {
    let message: String
    var actionTitle: String?
    var onActionTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let onActionTap {
                Button(actionTitle, action: onActionTap)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(AppTheme.tallAmber)
                    .accessibilityLabel("Undo last add")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(actionTitle == nil ? message : "\(message). Undo available.")
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.cardBackground.opacity(0.96), in: Capsule())
        .overlay(
            Capsule().stroke(AppTheme.outline.opacity(0.5), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
