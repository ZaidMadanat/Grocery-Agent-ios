//
//  SelectableChip.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/26/25.
//

import SwiftUI

struct SelectableChip: View {
    let title: String
    var systemImage: String?
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(isSelected ? .white : .accentColor)
                }
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .foregroundStyle(isSelected ? Color.white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isSelected)
    }

    private var background: AnyShapeStyle {
        if isSelected {
            AnyShapeStyle(LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing))
        } else {
            AnyShapeStyle(Color.agentSurfaceBackground)
        }
    }

    private var borderColor: Color {
        isSelected ? .clear : .accentColor.opacity(0.25)
    }
}

#Preview {
    VStack(spacing: 16) {
        SelectableChip(title: "Vegetarian", systemImage: "leaf", isSelected: true, action: {})
        SelectableChip(title: "Other", systemImage: "square.and.pencil", isSelected: false, action: {})
    }
    .padding()
    .background(Color.agentGroupedBackground)
}
