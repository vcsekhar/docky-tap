//
//  AnalyticsService.swift
//  Docky
//

import Combine
import Foundation
import PostHog

final class AnalyticsService {
    static let shared = AnalyticsService()

    private enum Keys {
        static let installID = "docky.analytics.installID"
        static let projectToken = "PostHogProjectToken"
        static let host = "PostHogHost"
    }

    private let defaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()
    private var isConfigured = false

    private var installID: String {
        if let existingID = defaults.string(forKey: Keys.installID), !existingID.isEmpty {
            return existingID
        }

        let newID = UUID().uuidString.lowercased()
        defaults.set(newID, forKey: Keys.installID)
        return newID
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        ProductService.shared.$currentTier
            .combineLatest(ProductService.shared.$hasStoredLicenseKey)
            .sink { [weak self] _, _ in
                self?.refreshIdentity()
            }
            .store(in: &cancellables)
    }

    func configureIfNeeded() {
        guard !isConfigured else {
            refreshIdentity()
            return
        }

        guard let projectToken = stringInfoValue(forKey: Keys.projectToken), !projectToken.isEmpty else {
            return
        }

        let config = PostHogConfig(
            projectToken: projectToken,
            host: stringInfoValue(forKey: Keys.host) ?? "https://us.i.posthog.com"
        )
        config.captureScreenViews = false
        config.personProfiles = .identifiedOnly
        #if DEBUG
        config.debug = true
        #endif

        PostHogSDK.shared.setup(config)
        isConfigured = true
        refreshIdentity()
    }

    private func refreshIdentity() {
        guard isConfigured else {
            return
        }

        let eventProperties = sharedProperties()
        PostHogSDK.shared.register(eventProperties)
        PostHogSDK.shared.identify(
            installID,
            userProperties: eventProperties,
            userPropertiesSetOnce: [
                "first_seen_app_version": shortVersion,
                "first_seen_build": buildNumber,
            ]
        )
    }

    private func sharedProperties() -> [String: Any] {
        [
            "app_version": shortVersion,
            "app_build": buildNumber,
            "product_tier": ProductService.shared.currentTier.rawValue,
            "has_stored_license_key": ProductService.shared.hasStoredLicenseKey,
            "has_completed_initial_onboarding": PermissionsService.shared.hasCompletedInitialOnboarding,
            "all_required_permissions_granted": PermissionsService.shared.allRequiredGranted,
        ]
    }

    private func stringInfoValue(forKey key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    private var shortVersion: String {
        stringInfoValue(forKey: "CFBundleShortVersionString") ?? "unknown"
    }

    private var buildNumber: String {
        stringInfoValue(forKey: "CFBundleVersion") ?? "unknown"
    }
}
