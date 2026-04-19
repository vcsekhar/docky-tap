//
//  AppTileView.swift
//  Docky
//

import AppKit
import SwiftUI

struct AppTileView: View {
    let tile: AppTile
    @ObservedObject private var workspace = WorkspaceService.shared

    private var isRunning: Bool {
        workspace.isRunning(bundleIdentifier: tile.bundleIdentifier)
    }

    private var isHidden: Bool {
        workspace.isHidden(bundleIdentifier: tile.bundleIdentifier)
    }

    var body: some View {
        iconView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var iconView: some View {
        Image(nsImage: icon)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .opacity(isHidden ? 0.5 : 1)
    }

    private var icon: NSImage {
        IconCacheService.shared.icon(forBundleIdentifier: tile.bundleIdentifier)
    }
}
