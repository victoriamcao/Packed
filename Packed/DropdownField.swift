//
//  DropdownField.swift
//  Packed
//
//  A dropdown styled to match the rest of the app (buttonGray box,
//  lightBlue accent, rounded corners) instead of the system Menu's
//  plain white popup, which looks out of place next to the app's
//  custom-styled fields. The option list floats over the page as an
//  overlay rather than pushing content down, so it doesn't disturb
//  the rest of a layout tuned to fit on one screen.
//

import SwiftUI

struct DropdownField: View {
    let options: [String]
    @Binding var selection: String
    @Binding var isExpanded: Bool
    /// What VoiceOver calls this control, e.g. "Type of vacation".
    var accessibilityTitle: String = ""

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        } label: {
            HStack {
                Text(selection)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Color("lightBlue"))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: 350, minHeight: 44)
            .background(Color("buttonGray"))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("lightBlue"), lineWidth: isExpanded ? 1.5 : 0)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityValue(selection)
        .accessibilityHint(isExpanded ? "Double tap to close" : "Double tap to choose")
        .overlay(alignment: .top) {
            if isExpanded {
                optionsList
                    .offset(y: 48)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .zIndex(isExpanded ? 10 : 0)
    }

    private var optionsList: some View {
        VStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = false
                    }
                } label: {
                    HStack {
                        Text(option)
                            .foregroundColor(option == selection ? .white : .primary)
                        Spacer()
                        if option == selection {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .background(option == selection ? Color("lightBlue") : Color("buttonGray"))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(option == selection ? .isSelected : [])

                if option != options.last {
                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .frame(maxWidth: 350)
        .background(Color("buttonGray"))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color("lightBlue").opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}
