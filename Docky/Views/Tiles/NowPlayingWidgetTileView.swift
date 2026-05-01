//
//  NowPlayingWidgetTileView.swift
//  Docky
//

import AppKit
import CoreImage
import SwiftUI

struct NowPlayingWidgetTileView: View {
    let tile: WidgetTile
    let cornerRadius: CGFloat
    let renderedSpan: TileSpan
    let isWithinStack: Bool
    var isExpanded: Bool = false
    @ObservedObject private var mediaPlayback = MediaPlaybackService.shared
    @State private var isHovering = false

    var body: some View {
        GeometryReader { proxy in
            let layout = layout(in: proxy.size)
            let expandedLayout = expandedLayout(in: proxy.size)

            ZStack {
                Color(nsColor: prominentTintColor)
                    .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))

                if !isWithinStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                }

                content(layout: layout)
                    .opacity(isExpanded ? 0 : 1)
                    .animation(.easeOut(duration: 0.12), value: isExpanded)

                if isExpanded {
                    expandedContent(layout: expandedLayout)
                        .overlay {
                            VStack {
                                Text(proxy.size.debugDescription)
                                Spacer()
                            }
                        }
                        .frame(height: proxy.size.height)
                        .transition(
                            .opacity.animation(
                                .easeInOut(duration: 0.22).delay(0.22)
                            ).combined(with: .scale).combined(with: .slide)
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private func content(layout: LayoutMetrics) -> some View {
        switch renderedSpan {
        case .one:
            nowPlayingOneUp(layout: layout)
        case .two:
            nowPlayingTwoUp(layout: layout)
        case .three:
            nowPlayingThreeUp(layout: layout)
        }
    }

    private func nowPlayingOneUp(layout: LayoutMetrics) -> some View {
        artworkView(size: nil, artworkCornerRadius: layout.artworkCornerRadius)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay {
                if isHovering {
                    ZStack {
                        Color.black.opacity(0.18)

                        Image(systemName: playbackState?.isPlaying == true ? "pause.fill" : "play.fill")
                            .font(.system(size: layout.largeGlyphSize, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                            .offset(x: playbackState?.isPlaying == true ? 0 : -layout.largeGlyphSize * 0.06)
                    }
                    .transition(.opacity)
                }
            }
            .onHover { isHovering = $0 }
    }

    private func nowPlayingTwoUp(layout: LayoutMetrics) -> some View {
        HStack(spacing: layout.contentGap) {
            artworkView(size: layout.artworkSize, artworkCornerRadius: layout.artworkCornerRadius)

            HStack(spacing: layout.controlClusterSpacing) {
                controlButton("backward.fill", layout: layout, action: skipToPrevious)
                controlButton(
                    playbackState?.isPlaying == true ? "pause.fill" : "play.fill",
                    layout: layout,
                    action: togglePlayPause
                )
                controlButton("forward.fill", layout: layout, action: skipToNext)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .padding(layout.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func nowPlayingThreeUp(layout: LayoutMetrics) -> some View {
        HStack(spacing: layout.contentGap) {
            artworkView(size: layout.artworkSize, artworkCornerRadius: layout.artworkCornerRadius)

            VStack(alignment: .leading, spacing: layout.stackSpacing) {
                Text(playbackState?.isPresentable == false ? (playbackState?.title ?? "Not Playing") : playbackTitle)
                    .font(.system(size: layout.titleFontSize, weight: .semibold))
                    .foregroundStyle(primaryForegroundColor)
                    .lineLimit(1)

                if playbackArtist.isEmpty == false {
                    Text(playbackArtist)
                        .font(.system(size: layout.subtitleFontSize))
                        .foregroundStyle(secondaryForegroundColor)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: layout.contentGap) {
                controlButton(
                    playbackState?.isPlaying == true ? "pause.fill" : "play.fill",
                    layout: layout,
                    action: togglePlayPause
                )
                controlButton("forward.fill", layout: layout, action: skipToNext)
            }
            .fixedSize()
            .padding(.trailing, layout.trailingControlPadding)
        }
        .padding(layout.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func expandedContent(layout: ExpandedLayoutMetrics) -> some View {
        HStack(spacing: layout.contentGap) {
            artworkView(size: layout.artworkSize, artworkCornerRadius: layout.artworkCornerRadius)
                .frame(width: layout.artworkSize, height: layout.artworkSize)
                .shadow(color: .black.opacity(0.18), radius: layout.artworkSize * 0.05, x: 0, y: layout.artworkSize * 0.03)

            VStack(alignment: .leading, spacing: layout.sectionSpacing) {
                VStack(alignment: .leading, spacing: layout.titleStackSpacing) {
                    Text(playbackTitle)
                        .font(.system(size: layout.titleFontSize, weight: .semibold))
                        .foregroundStyle(primaryForegroundColor)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(secondaryDescription)
                        .font(.system(size: layout.subtitleFontSize, weight: .medium))
                        .foregroundStyle(secondaryForegroundColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer(minLength: 0)

                controlRow(layout: layout)

                progressSection(layout: layout)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(layout.contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func progressSection(layout: ExpandedLayoutMetrics) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let elapsed = playbackState?.estimatedCurrentTime ?? 0
            let total = max(playbackState?.duration ?? 0, 0)
            let progress: Double = total > 0 ? min(max(elapsed / total, 0), 1) : 0
            let remaining = max(total - elapsed, 0)

            VStack(spacing: layout.progressLabelSpacing) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(secondaryForegroundColor.opacity(0.28))

                        Capsule(style: .continuous)
                            .fill(primaryForegroundColor)
                            .frame(width: max(0, proxy.size.width * progress))
                    }
                }
                .frame(height: layout.progressBarHeight)

                HStack {
                    Text(formatPlaybackTime(elapsed))
                        .foregroundStyle(secondaryForegroundColor)
                    Spacer(minLength: 0)
                    Text(total > 0 ? "-\(formatPlaybackTime(remaining))" : formatPlaybackTime(elapsed))
                        .foregroundStyle(secondaryForegroundColor)
                }
                .font(.system(size: layout.timestampFontSize, weight: .medium, design: .rounded))
                .monospacedDigit()
            }
        }
    }

    private func controlRow(layout: ExpandedLayoutMetrics) -> some View {
        HStack(spacing: layout.controlClusterSpacing) {
            expandedControlButton(
                "backward.fill",
                size: layout.controlButtonSize,
                iconSize: layout.controlIconSize,
                action: skipToPrevious
            )

            expandedControlButton(
                playbackState?.isPlaying == true ? "pause.fill" : "play.fill",
                size: layout.primaryControlButtonSize,
                iconSize: layout.primaryControlIconSize,
                action: togglePlayPause
            )

            expandedControlButton(
                "forward.fill",
                size: layout.controlButtonSize,
                iconSize: layout.controlIconSize,
                action: skipToNext
            )

            if playbackState?.supportsFavorite == true {
                expandedControlButton(
                    playbackState?.isFavorite == true ? "heart.fill" : "heart",
                    size: layout.controlButtonSize,
                    iconSize: layout.controlIconSize,
                    action: toggleFavorite
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func expandedControlButton(_ systemName: String, size: CGFloat, iconSize: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(primaryForegroundColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(secondaryForegroundColor.opacity(0.18))
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var secondaryDescription: String {
        let artist = playbackArtist
        let album = playbackState?.album ?? ""
        let parts = [artist, album].filter { !$0.isEmpty }
        return parts.isEmpty ? ownerDisplayName : parts.joined(separator: " • ")
    }

    private func formatPlaybackTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded())
        let minutes = total / 60
        let remainder = total % 60
        let hours = minutes / 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes % 60, remainder)
        }
        return String(format: "%d:%02d", minutes, remainder)
    }

    private func toggleFavorite() {
        let next = !(playbackState?.isFavorite ?? false)
        Task {
            await mediaPlayback.setFavorite(next, for: tile.ownerBundleIdentifier)
        }
    }

    @ViewBuilder
    private func artworkView(size: CGFloat?, artworkCornerRadius: CGFloat) -> some View {
        if let artworkData = playbackState?.artworkData,
           let artworkImage = NSImage(data: artworkData),
           playbackState?.isPresentable == true {
            Image(nsImage: artworkImage)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: artworkCornerRadius, style: .continuous))
        } else {
            Color.primary
                .opacity(0.06)
                .aspectRatio(contentMode: size == nil ? .fill : .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: artworkCornerRadius, style: .continuous))
        }
    }

    private func controlButton(_ systemName: String, layout: LayoutMetrics, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: layout.controlIconSize, weight: .semibold))
                .foregroundStyle(primaryForegroundColor)
                .frame(width: layout.controlButtonSize, height: layout.controlButtonSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func expandedLayout(in size: CGSize) -> ExpandedLayoutMetrics {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        let minSide = min(width, height)
        let contentPadding = min(max(minSide * 0.07, 12), 22)
        let contentGap = min(max(minSide * 0.05, 12), 22)
        let sectionSpacing = min(max(minSide * 0.04, 8), 16)
        let titleStackSpacing = min(max(minSide * 0.012, 2), 6)
        let progressBarHeight = min(max(minSide * 0.018, 4), 7)
        let progressLabelSpacing = min(max(minSide * 0.012, 3), 6)

        let availableHeight = max(0, height - contentPadding * 2)
        let artworkSize = availableHeight

        let primaryControlButtonSize = min(max(minSide * 0.16, 36), 60)
        let controlButtonSize = min(max(minSide * 0.12, 28), 46)

        return ExpandedLayoutMetrics(
            contentPadding: contentPadding,
            contentGap: contentGap,
            sectionSpacing: sectionSpacing,
            titleStackSpacing: titleStackSpacing,
            artworkSize: artworkSize,
            artworkCornerRadius: min(max(artworkSize * 0.08, 8), 18),
            titleFontSize: min(max(minSide * 0.07, 14), 22),
            subtitleFontSize: min(max(minSide * 0.05, 11), 16),
            progressBarHeight: progressBarHeight,
            progressLabelSpacing: progressLabelSpacing,
            timestampFontSize: min(max(minSide * 0.04, 10), 13),
            controlClusterSpacing: min(max(minSide * 0.04, 10), 18),
            primaryControlButtonSize: primaryControlButtonSize,
            primaryControlIconSize: primaryControlButtonSize * 0.5,
            controlButtonSize: controlButtonSize,
            controlIconSize: controlButtonSize * 0.5
        )
    }

    private func layout(in size: CGSize) -> LayoutMetrics {
        let width = max(size.width, 1)
        let height = max(size.height, 1)
        let minSide = min(width, height)
        let contentPadding = min(max(minSide * 0.12, 4), minSide * 0.18)
        let availableHeight = max(0, height - contentPadding * 2)
        let contentGap = min(max(minSide * 0.1, 4), minSide * 0.2)
        let stackSpacing = min(max(minSide * 0.05, 2), minSide * 0.1)
        let controlClusterSpacing = min(max(minSide * 0.08, 4), minSide * 0.14)
        let controlButtonSize = min(max(minSide * 0.24, 16), availableHeight)
        let artworkWidthFraction: CGFloat = renderedSpan == .two ? 0.34 : 0.24
        let artworkSize = min(availableHeight, width * artworkWidthFraction)
        let artworkCornerRadius = min(artworkSize / 2, max(0, cornerRadius - contentPadding))
        let titleFontSize = min(max(minSide * 0.18, 11), 16)
        let subtitleFontSize = min(max(minSide * 0.14, 9), 13)
        let controlIconSize = min(max(controlButtonSize * 0.72, 11), controlButtonSize)
        let largeGlyphSize = min(max(minSide * 0.42, 18), minSide * 0.56)

        return LayoutMetrics(
            contentPadding: contentPadding,
            contentGap: contentGap,
            controlClusterSpacing: controlClusterSpacing,
            stackSpacing: stackSpacing,
            trailingControlPadding: stackSpacing,
            artworkSize: artworkSize,
            artworkCornerRadius: artworkCornerRadius,
            titleFontSize: titleFontSize,
            subtitleFontSize: subtitleFontSize,
            controlIconSize: controlIconSize,
            controlButtonSize: controlButtonSize,
            largeGlyphSize: largeGlyphSize
        )
    }

    private var playbackState: MediaPlaybackState? {
        mediaPlayback.state(for: tile.ownerBundleIdentifier)
    }

    private var prominentTintColor: NSColor {
        guard playbackState?.isPresentable == true else {
            return (NSColor.windowBackgroundColor.blended(withFraction: 0.18, of: .black) ?? .windowBackgroundColor)
        }
        
        if let artworkData = playbackState?.artworkData,
           let artworkImage = NSImage(data: artworkData),
           let extractedColor = Self.prominentColor(from: artworkImage) {
            return extractedColor.usingColorSpace(.deviceRGB) ?? extractedColor
        }

        return (NSColor.windowBackgroundColor.blended(withFraction: 0.18, of: .black) ?? .windowBackgroundColor)
    }

    private var usesDarkForeground: Bool {
        prominentTintColor.perceivedLuminance > 0.62
    }

    private var primaryForegroundColor: Color {
        Color(nsColor: usesDarkForeground ? .black.withAlphaComponent(0.82) : .white.withAlphaComponent(0.96))
    }

    private var secondaryForegroundColor: Color {
        Color(nsColor: usesDarkForeground ? .black.withAlphaComponent(0.56) : .white.withAlphaComponent(0.72))
    }

    private var ownerDisplayName: String {
        playbackState?.displayName
            ?? (NSWorkspace.shared.urlForApplication(withBundleIdentifier: tile.ownerBundleIdentifier).map {
                FileManager.default.displayName(atPath: $0.path)
            } ?? "")
    }

    private var playbackTitle: String {
        guard let playbackState, playbackState.hasContent else {
            return "Not Playing"
        }

        return playbackState.title.isEmpty ? ownerDisplayName : playbackState.title
    }

    private var playbackArtist: String {
        guard let playbackState, playbackState.hasContent else {
            return ownerDisplayName
        }

        if !playbackState.artist.isEmpty {
            return playbackState.artist
        }

        return ownerDisplayName
    }

    private func togglePlayPause() {
        Task {
            await mediaPlayback.pressPlayPauseButton(for: tile.ownerBundleIdentifier)
        }
    }

    private func skipToNext() {
        Task {
            await mediaPlayback.skipToNext(for: tile.ownerBundleIdentifier)
        }
    }

    private func skipToPrevious() {
        Task {
            await mediaPlayback.skipToPrevious(for: tile.ownerBundleIdentifier)
        }
    }

    private static let ciContext = CIContext(options: nil)

    private static func prominentColor(from image: NSImage) -> NSColor? {
        guard let tiffData = image.tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else {
            return nil
        }

        let extent = ciImage.extent
        guard !extent.isEmpty,
              let filter = CIFilter(name: "CIAreaAverage") else {
            return nil
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

        guard let outputImage = filter.outputImage else {
            return nil
        }

        var rgba = [UInt8](repeating: 0, count: 4)
        ciContext.render(
            outputImage,
            toBitmap: &rgba,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        let baseColor = NSColor(
            red: CGFloat(rgba[0]) / 255,
            green: CGFloat(rgba[1]) / 255,
            blue: CGFloat(rgba[2]) / 255,
            alpha: 1
        )

        return baseColor.withSystemEffect(.pressed)
    }
}

private struct LayoutMetrics {
    let contentPadding: CGFloat
    let contentGap: CGFloat
    let controlClusterSpacing: CGFloat
    let stackSpacing: CGFloat
    let trailingControlPadding: CGFloat
    let artworkSize: CGFloat
    let artworkCornerRadius: CGFloat
    let titleFontSize: CGFloat
    let subtitleFontSize: CGFloat
    let controlIconSize: CGFloat
    let controlButtonSize: CGFloat
    let largeGlyphSize: CGFloat
}

private struct ExpandedLayoutMetrics {
    let contentPadding: CGFloat
    let contentGap: CGFloat
    let sectionSpacing: CGFloat
    let titleStackSpacing: CGFloat
    let artworkSize: CGFloat
    let artworkCornerRadius: CGFloat
    let titleFontSize: CGFloat
    let subtitleFontSize: CGFloat
    let progressBarHeight: CGFloat
    let progressLabelSpacing: CGFloat
    let timestampFontSize: CGFloat
    let controlClusterSpacing: CGFloat
    let primaryControlButtonSize: CGFloat
    let primaryControlIconSize: CGFloat
    let controlButtonSize: CGFloat
    let controlIconSize: CGFloat
}

private extension NSColor {
    var perceivedLuminance: CGFloat {
        guard let rgbColor = usingColorSpace(.deviceRGB) else {
            return 0
        }

        return (0.2126 * rgbColor.redComponent) + (0.7152 * rgbColor.greenComponent) + (0.0722 * rgbColor.blueComponent)
    }
}
