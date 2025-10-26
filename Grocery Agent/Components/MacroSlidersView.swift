//
//  MacroSlidersView.swift
//  Grocery Agent
//
//  Created by Zaid Madanat on 10/26/25.
//

import SwiftUI

struct MacroSlidersView: View {
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fats: Double

    let onChange: (Double, Double, Double) -> Void

    init(
        protein: Double,
        carbs: Double,
        fats: Double,
        onChange: @escaping (Double, Double, Double) -> Void
    ) {
        _protein = State(initialValue: protein)
        _carbs = State(initialValue: carbs)
        _fats = State(initialValue: fats)
        self.onChange = onChange
    }

    var body: some View {
        VStack(spacing: 24) {
            metricRow(
                title: "Protein",
                icon: "bolt.fill",
                color: .orange,
                value: protein
            ) {
                protein = $0
                propagate()
            }

            metricRow(
                title: "Carbs",
                icon: "leaf.fill",
                color: .mint,
                value: carbs
            ) {
                carbs = $0
                propagate()
            }

            metricRow(
                title: "Fats",
                icon: "drop.fill",
                color: .pink,
                value: fats
            ) {
                fats = $0
                propagate()
            }

            totalSummary
        }
        .onAppear(perform: propagate)
    }

    private var totalSummary: some View {
        let total = max(protein + carbs + fats, 0.01)
        let normalizedProtein = protein / total
        let normalizedCarbs = carbs / total
        let normalizedFats = fats / total

        return VStack(alignment: .leading, spacing: 8) {
            Text("Macro Balance")
                .font(.title3.bold())
            ProgressView(value: normalizedProtein)
                .tint(.orange)
                .overlay(alignment: .leading) {
                    Text("Protein \(Int(normalizedProtein * 100))%")
                        .font(.caption.bold())
                        .offset(y: -18)
                }
            ProgressView(value: normalizedCarbs)
                .tint(.mint)
                .overlay(alignment: .leading) {
                    Text("Carbs \(Int(normalizedCarbs * 100))%")
                        .font(.caption.bold())
                        .offset(y: -18)
                }
            ProgressView(value: normalizedFats)
                .tint(.pink)
                .overlay(alignment: .leading) {
                    Text("Fats \(Int(normalizedFats * 100))%")
                        .font(.caption.bold())
                        .offset(y: -18)
                }
            Text("Total weight \(Int(total * 100))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func metricRow(
        title: String,
        icon: String,
        color: Color,
        value: Double,
        onChange: @escaping (Double) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(color)
            Slider(value: Binding(
                get: { value },
                set: { newValue in
                    onChange(newValue)
                }
            ), in: 0...1, step: 0.05)
            .tint(color)
        }
    }

    private func propagate() {
        onChange(protein, carbs, fats)
    }
}

#Preview {
    MacroSlidersView(protein: 0.4, carbs: 0.35, fats: 0.25, onChange: { _, _, _ in })
        .padding()
}
