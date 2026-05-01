//
//  WidgetExpansionWindowController.swift
//  Docky
//

import AppKit
import Combine
import SwiftUI

final class WidgetExpansionWindowController: NSWindowController, ObservableObject {
    static let shared = WidgetExpansionWindowController()

    @Published private(set) var activeSourceTileID: String?

    private static let contentPadding: CGFloat = 8
    private static let animationDuration: TimeInterval = 0.18
    private static let slideOffset: CGFloat = 12

    private var currentTileID: String?
    private var isPreviewHovered = false
    private var isHoldingDockVisible = false
    private weak var heldMainWindow: MainWindow?
    private var pendingDismissTask: Task<Void, Never>?
    private var dismissAnimationTask: Task<Void, Never>?

    private init() {
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.level = .mainMenu
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(
        widget: WidgetTile,
        sourceTileID: String,
        sourceFrame: CGRect,
        cornerRadius: CGFloat,
        renderedSpan: TileSpan
    ) {
        guard let window else { return }

        currentTileID = sourceTileID
        activeSourceTileID = sourceTileID
        pendingDismissTask?.cancel()
        pendingDismissTask = nil
        dismissAnimationTask?.cancel()
        dismissAnimationTask = nil
        beginDockVisibilityHoldIfNeeded()

        let baseTileSize = max(1, min(
            sourceFrame.height,
            sourceFrame.width / CGFloat(max(renderedSpan.rawValue, 1))
        ))
        let extent = widget.kind.expansionExtent
        let size = CGSize(
            width: baseTileSize * CGFloat(extent.widthTiles),
            height: baseTileSize * CGFloat(extent.heightTiles)
        )
        let windowSize = CGSize(
            width: size.width + Self.contentPadding * 2,
            height: size.height + Self.contentPadding * 2
        )

        let rootView = ZStack {
            Color.clear

            WidgetTileView(
                tile: widget,
                cornerRadius: cornerRadius,
                renderedSpan: renderedSpan,
                isWithinStack: false,
                isExpanded: true,
                isExpandedPreviewOpen: true
            )
            .frame(width: size.width, height: size.height)
            .padding(Self.contentPadding)
        }
        .frame(width: windowSize.width, height: windowSize.height)
        .contentShape(Rectangle())
        .onHover { isHovering in
            WidgetExpansionWindowController.shared.setPreviewHovered(isHovering, sourceTileID: sourceTileID)
        }

        let finalOrigin = frameOrigin(for: windowSize, sourceFrame: sourceFrame)
        let initialOrigin = CGPoint(x: finalOrigin.x, y: finalOrigin.y - Self.slideOffset)
        let finalFrame = CGRect(origin: finalOrigin, size: windowSize)
        let initialFrame = CGRect(origin: initialOrigin, size: windowSize)

        window.contentView = NSHostingView(rootView: rootView)
        window.setFrame(initialFrame, display: false)
        window.alphaValue = 0
        window.orderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(finalFrame, display: true)
            window.animator().alphaValue = 1
        }
    }

    func dismiss(sourceTileID: String) {
        guard currentTileID == sourceTileID else { return }
        pendingDismissTask?.cancel()
        pendingDismissTask = nil
        isPreviewHovered = false
        endDockVisibilityHoldIfNeeded()
        currentTileID = nil
        activeSourceTileID = nil

        guard let window, window.isVisible else {
            close()
            return
        }

        let currentFrame = window.frame
        let targetFrame = currentFrame.offsetBy(dx: 0, dy: -Self.slideOffset)

        dismissAnimationTask?.cancel()
        dismissAnimationTask = Task { @MainActor in
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = Self.animationDuration
                    context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                    window.animator().setFrame(targetFrame, display: true)
                    window.animator().alphaValue = 0
                }, completionHandler: {
                    continuation.resume()
                })
            }
            if Task.isCancelled { return }
            guard self.currentTileID == nil else { return }
            self.close()
        }
    }

    func requestDismiss(sourceTileID: String) {
        guard currentTileID == sourceTileID else { return }
        guard !isPreviewHovered else { return }

        pendingDismissTask?.cancel()
        pendingDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            guard self.currentTileID == sourceTileID, !self.isPreviewHovered else { return }
            self.dismiss(sourceTileID: sourceTileID)
        }
    }

    private func setPreviewHovered(_ isHovered: Bool, sourceTileID: String) {
        guard currentTileID == sourceTileID else { return }
        isPreviewHovered = isHovered

        if isHovered {
            pendingDismissTask?.cancel()
            pendingDismissTask = nil
        } else {
            requestDismiss(sourceTileID: sourceTileID)
        }
    }

    private func beginDockVisibilityHoldIfNeeded() {
        guard !isHoldingDockVisible else { return }
        guard let mainWindow = NSApp.windows.compactMap({ $0 as? MainWindow }).first else { return }

        mainWindow.beginInteraction()
        heldMainWindow = mainWindow
        isHoldingDockVisible = true
    }

    private func endDockVisibilityHoldIfNeeded() {
        guard isHoldingDockVisible else { return }

        heldMainWindow?.endInteraction()
        heldMainWindow = nil
        isHoldingDockVisible = false
    }

    private func frameOrigin(for size: CGSize, sourceFrame: CGRect) -> CGPoint {
        let screen = NSScreen.screens.first { $0.visibleFrame.intersects(sourceFrame) } ?? NSScreen.main
        guard let visibleFrame = screen?.visibleFrame else {
            return CGPoint(x: sourceFrame.midX - size.width / 2, y: sourceFrame.maxY)
        }

        let proposedY = sourceFrame.maxY
        let y = proposedY + size.height <= visibleFrame.maxY
            ? proposedY
            : max(visibleFrame.minY, sourceFrame.minY - size.height)
        let x = min(
            max(sourceFrame.midX - size.width / 2, visibleFrame.minX),
            visibleFrame.maxX - size.width
        )

        return CGPoint(x: x, y: y)
    }
}
