//
//  LicensingWindowController.swift
//  Docky
//

import AppKit
import SwiftUI

/// Which section the licensing window should land on when opened, so the
/// CTA that brought the user here (buy / trial / existing license) points
/// them at the matching form.
enum LicensingSection {
    case license
    case trial
}

@MainActor
final class LicensingWindowController: NSWindowController, NSWindowDelegate {
    private static var sharedController: LicensingWindowController?

    static func present(focus: LicensingSection = .license) {
        if let controller = sharedController, controller.window != nil {
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = LicensingWindowController(focus: focus)
        sharedController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    convenience init(focus: LicensingSection = .license) {
        let hostingController = NSHostingController(rootView: LicensingView(initialFocus: focus))
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 480, height: 540))
        window.minSize = NSSize(width: 440, height: 420)
        window.styleMask = [.titled, .closable, .resizable, .fullSizeContentView]
        window.title = "Licensing"
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.isReleasedWhenClosed = false
        self.init(window: window)
        window.delegate = self
    }

    func windowWillClose(_ notification: Notification) {
        Self.sharedController = nil
    }
}
