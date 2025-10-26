//
//  InventoryView.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/26/25.
//

import SwiftUI

struct InventoryView: View {
    @ObservedObject var appModel: AppViewModel
    @StateObject private var viewModel: InventoryViewModel
    @State private var editedQuantity: String = ""

    init(appModel: AppViewModel) {
        self.appModel = appModel
        _viewModel = StateObject(wrappedValue: InventoryViewModel(appModel: appModel))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.groupedByCategory, id: \.key) { category, items in
                    Section(category) {
                        ForEach(items) { item in
                            InventoryRow(item: item, descriptor: viewModel.color(for: item.statusColor)) { newQuantity in
                                viewModel.updateQuantity(for: item, quantity: newQuantity)
                            } onRemove: {
                                viewModel.remove(item)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Inventory")
        }
    }
}

private struct InventoryRow: View {
    let item: InventoryItem
    let descriptor: InventoryViewModel.ColorDescriptor
    var onUpdate: (String) -> Void
    var onRemove: () -> Void
    @State private var quantity: String

    init(
        item: InventoryItem,
        descriptor: InventoryViewModel.ColorDescriptor,
        onUpdate: @escaping (String) -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.item = item
        self.descriptor = descriptor
        self.onUpdate = onUpdate
        self.onRemove = onRemove
        _quantity = State(initialValue: item.quantity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(item.name)
                    .font(.headline)
                Spacer()
                Text(descriptor.label)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(descriptor.color.opacity(0.15), in: Capsule())
            }

            HStack {
                Label("\(item.daysUntilExpiry) days left", systemImage: "clock")
                    .foregroundStyle(descriptor.color)
                Spacer()
                TextField("Qty", text: $quantity, onCommit: {
                    onUpdate(quantity)
                })
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            if item.daysUntilExpiry <= 2 {
                Label("Notification scheduled", systemImage: "bell.badge")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .onChange(of: quantity) { newValue in
            onUpdate(newValue)
        }
    }
}

#Preview {
    InventoryView(appModel: AppViewModel())
}
