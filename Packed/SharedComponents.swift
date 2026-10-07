//
//  SharedComponents.swift
//  Packed
//
//  Small views and helpers used by more than one screen.
//

import SwiftUI

/// Password/requirement checklist row - a checkmark or x that flips
/// red -> green live as the requirement becomes met. Used by signup,
/// change password, and reset password.
struct RequirementView: View {
    let met: Bool
    let text: String

    var body: some View {
        HStack {
            Image(systemName: met ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(met ? .green : .red)
                .accessibilityHidden(true)
            Text(text)
                .font(.caption)
                .foregroundColor(met ? .green : .red)
        }
        .animation(.easeInOut(duration: 0.2), value: met)
        .accessibilityElement(children: .combine)
        .accessibilityValue(met ? "Met" : "Not met")
    }
}

/// Shown instead of an empty state when loading failed, so an offline
/// user doesn't think their saved data is gone.
struct LoadErrorView: View {
    let message: String
    var retry: () async -> Void
    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundColor(Color("lightBlue"))
                .accessibilityHidden(true)
            Text(message)
                .font(.subheadline)
                .foregroundColor(Color("textGray"))
                .multilineTextAlignment(.center)
            Button {
                Task {
                    isRetrying = true
                    await retry()
                    isRetrying = false
                }
            } label: {
                Text(isRetrying ? "Retrying..." : "Try Again")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color("lightBlue"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isRetrying)
        }
        .padding()
    }
}

/// Plain-text version of a packing list for the share sheet (Messages,
/// Notes, email, AirDrop...).
enum PackingListExport {
    static func text(title: String, items: [PackingItem]) -> String {
        let grouped = Dictionary(grouping: items, by: \.category)
        var lines = [title, ""]
        for category in grouped.keys.sorted() {
            lines.append(category.uppercased())
            for item in grouped[category] ?? [] {
                lines.append("\(item.isPacked ? "[x]" : "[ ]") \(item.name)")
            }
            lines.append("")
        }
        lines.append("Made with Packed")
        return lines.joined(separator: "\n")
    }
}
