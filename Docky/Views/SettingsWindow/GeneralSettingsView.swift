//
//  GeneralSettingsView.swift
//  Docky
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject private var preferences = DockyPreferences.shared

    var body: some View {
        Form {
            Section("Appearance") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tile Vertical Padding")
                        .font(.headline)

                    HStack {
                        Slider(value: $preferences.tileVerticalPadding, in: 8...32, step: 1) {
                            Text("Tile Vertical Padding")
                        }
                        Text("\(Int(preferences.tileVerticalPadding)) pt")
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                    }

                    Text("Controls the top and bottom inset inside each dock tile.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Window Corner Radius")
                        .font(.headline)

                    HStack {
                        Slider(value: $preferences.windowCornerRadius, in: 0...24, step: 1) {
                            Text("Window Corner Radius")
                        }
                        Text("\(Int(preferences.windowCornerRadius)) pt")
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                    }

                    Text("Controls the roundness of the main dock window and its border.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tile Spacing")
                        .font(.headline)

                    HStack {
                        Slider(value: $preferences.tileSpacing, in: 0...16, step: 1) {
                            Text("Tile Spacing")
                        }
                        Text("\(Int(preferences.tileSpacing)) pt")
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .trailing)
                    }

                    Text("Controls the horizontal gap between adjacent dock tiles.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button("Reset to Defaults") {
                    preferences.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 20)
    }
}
