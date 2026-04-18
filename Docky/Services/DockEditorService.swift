//
//  DockEditorService.swift
//  Docky
//

import AppKit
import Foundation

final class DockEditorService {
    static let shared = DockEditorService()

    private static let dockBundleIdentifier = "com.apple.dock"
    private static let finderBundleIdentifier = "com.apple.finder"
    private static let dockPlistFilename = "com.apple.dock.plist"

    private init() {}

    @discardableResult
    func removePinnedApp(bundleIdentifier: String) -> Bool {
        guard !bundleIdentifier.isEmpty, bundleIdentifier != Self.finderBundleIdentifier else {
            return false
        }

        let removed = updateDockPlist { plist in
            guard var apps = plist["persistent-apps"] as? [[String: Any]] else {
                return false
            }

            let originalCount = apps.count
            apps.removeAll { entry in
                pinnedAppBundleIdentifier(in: entry) == bundleIdentifier
            }
            guard apps.count != originalCount else {
                return false
            }

            plist["persistent-apps"] = apps
            return true
        }

        guard removed else {
            return false
        }

        restartDock()
        TileStore.shared.refresh()
        return true
    }

    private func updateDockPlist(_ mutate: (inout [String: Any]) -> Bool) -> Bool {
        if let updated = PermissionsService.shared.withDockPlistURL({ url -> Bool? in
            guard let url else { return nil }
            return updateDockPlist(at: url, mutate)
        }) {
            return updated
        }

        guard !AppEnvironment.isSandboxed else {
            return false
        }

        let url = URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Preferences")
            .appendingPathComponent(Self.dockPlistFilename)
        return updateDockPlist(at: url, mutate)
    }

    private func updateDockPlist(
        at url: URL,
        _ mutate: (inout [String: Any]) -> Bool
    ) -> Bool {
        guard let data = try? Data(contentsOf: url) else {
            return false
        }

        var format = PropertyListSerialization.PropertyListFormat.binary
        guard var plist = (try? PropertyListSerialization.propertyList(
            from: data,
            options: [],
            format: &format
        )) as? [String: Any] else {
            return false
        }

        guard mutate(&plist) else {
            return false
        }

        guard let updatedData = try? PropertyListSerialization.data(
            fromPropertyList: plist,
            format: format,
            options: 0
        ) else {
            return false
        }

        do {
            try updatedData.write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    private func restartDock() {
        NSRunningApplication
            .runningApplications(withBundleIdentifier: Self.dockBundleIdentifier)
            .forEach { $0.forceTerminate() }
    }

    private func pinnedAppBundleIdentifier(in entry: [String: Any]) -> String? {
        let tileData = entry["tile-data"] as? [String: Any]
        let fileData = tileData?["file-data"] as? [String: Any]
        let urlString = fileData?["_CFURLString"] as? String
        let url = urlString.flatMap(URL.init(string:))

        return (tileData?["bundle-identifier"] as? String)
            ?? url.flatMap { Bundle(url: $0)?.bundleIdentifier }
    }
}
