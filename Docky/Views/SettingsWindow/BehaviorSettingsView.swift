//
//  BehaviorSettingsView.swift
//  Docky
//

import SwiftUI

struct BehaviorSettingsView: View {
    @ObservedObject private var preferences = DockyPreferences.shared

    var body: some View {
        Form {
            Section("Placement") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Window Position")
                        .font(.headline)

                    Picker("Window Position", selection: $preferences.windowPosition) {
                        ForEach(DockWindowPosition.allCases) { position in
                            Text(position.title).tag(position)
                        }
                    }
                    .pickerStyle(.menu)

                    Text("Choose where Docky sits on screen, or mirror the macOS Dock position.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            Section("Visibility") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Autohide Window", isOn: $preferences.autohidesWindow)
                        .font(.headline)

                    Text("Slides Docky's window off-screen until the pointer reaches its edge. Reveal and hide timing still follows the system Dock settings.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 4)
            }

            Section("System Dock") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Hide System Dock", isOn: $preferences.hidesSystemDock)
                        .font(.headline)

                    Text("Forces the macOS Dock to autohide with a long delay and disables bouncing and launch animations. Docky snapshots your current Dock settings first and restores them when you turn this off or quit Docky.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Restore System Dock") {
                        preferences.hidesSystemDock = false
                    }
                    .disabled(!preferences.hidesSystemDock)
                }
                .padding(.vertical, 4)
            }

            Section("App Folders") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Shows Grouped Opened Apps In Dock", isOn: $preferences.showsGroupedOpenedAppsInDock)
                        .font(.headline)

                    Text("Shows running apps from an app folder immediately to the right of that folder, and lets the folder reflect how many grouped apps are open.")
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
