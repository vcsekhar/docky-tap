//
//  MainWindowView.swift
//  Docky
//
//  Created by Jose Quintero on 17/04/26.
//

import AppKit
import Combine
import SwiftUI

final class MainWindowView: NSView {
    override var wantsUpdateLayer: Bool { true }

    private let borderWidth: CGFloat = 1
    private let preferences = DockyPreferences.shared
    private let borderLayer = CAGradientLayer()
    private var cancellables: Set<AnyCancellable> = []

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func layout() {
        super.layout()
        updateBorderLayer(cornerRadius: preferences.windowCornerRadius)
    }

    override func updateLayer() {
        guard let layer else { return }

        let cornerRadius = preferences.windowCornerRadius

        layer.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.2).cgColor
        layer.cornerCurve = .continuous
        layer.cornerRadius = cornerRadius
        updateBorderLayer(cornerRadius: cornerRadius)
    }

    private func setup() {
        wantsLayer = true
        borderLayer.actions = ["bounds": NSNull(), "position": NSNull()]
        layer?.addSublayer(borderLayer)

        let hosting = ClickThroughHostingView(rootView: TileContainerView())
        hosting.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hosting)
        NSLayoutConstraint.activate([
            hosting.topAnchor.constraint(equalTo: topAnchor),
            hosting.bottomAnchor.constraint(equalTo: bottomAnchor),
            hosting.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        Publishers.Merge(preferences.$tileVerticalPadding.map { _ in () }, preferences.$windowCornerRadius.map { _ in () })
            .sink { [weak self] _ in self?.needsDisplay = true }
            .store(in: &cancellables)
    }

    private func borderMask(in rect: CGRect, cornerRadius: CGFloat) -> CAShapeLayer {
        let localRect = CGRect(origin: .zero, size: rect.size)
        let strokeRect = localRect.insetBy(dx: borderWidth, dy: borderWidth)

        let mask = CAShapeLayer()
        mask.frame = localRect
        mask.path = CGPath(
            roundedRect: strokeRect,
            cornerWidth: max(cornerRadius - borderWidth / 2, 0),
            cornerHeight: max(cornerRadius - borderWidth / 2, 0),
            transform: nil
        )
        mask.fillColor = NSColor.clear.cgColor
        mask.strokeColor = NSColor.black.cgColor
        mask.lineWidth = borderWidth
        mask.contentsScale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
        return mask
    }

    private func updateBorderLayer(cornerRadius: CGFloat) {
        let borderFrame = bounds
        let borderCornerRadius = cornerRadius

        borderLayer.frame = borderFrame
        borderLayer.cornerCurve = .continuous
        borderLayer.cornerRadius = borderCornerRadius
        borderLayer.startPoint = CGPoint(x: 0, y: 1)
        borderLayer.endPoint = CGPoint(x: 1, y: 0)
        borderLayer.colors = [
            NSColor.white.withAlphaComponent(0.35).cgColor,
            NSColor.white.withAlphaComponent(0.12).cgColor,
            NSColor.white.withAlphaComponent(0.05).cgColor,
            NSColor.white.withAlphaComponent(0.12).cgColor,
            NSColor.white.withAlphaComponent(0.28).cgColor,
        ]
        borderLayer.locations = [0, 0.35, 0.65, 1]

        let mask = borderMask(in: borderLayer.bounds, cornerRadius: borderCornerRadius)
        borderLayer.mask = mask
    }
}

private final class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}
