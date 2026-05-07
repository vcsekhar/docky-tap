//
//  TrashTileView.swift
//  Docky
//

import AppKit
import SwiftUI

struct TrashTileView: View {
    @ObservedObject private var trash = TrashService.shared
    @ObservedObject private var preferences = DockyPreferences.shared

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
    }

    private var icon: NSImage {
        let state: TrashIconState = trash.isEmpty ? .empty : .full

        if let overrideURL = preferences.effectiveTrashIconOverrideURL(forState: state),
           let overrideImage = IconCacheService.shared.image(forImageFileURL: overrideURL) {
            return overrideImage
        }

        return NSImage(named: state.systemImageName)
            ?? NSImage(named: TrashIconState.empty.systemImageName)
            ?? NSImage()
    }
}
