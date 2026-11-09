import Foundation
import FamilyControls
import ManagedSettings

/// Puts Apple's Screen Time shield over the native Instagram app,
/// so you're nudged to use the reel-free version inside AntiSocial.
@MainActor
final class AppBlocker: ObservableObject {
    @Published var isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    @Published var isBlocking: Bool
    @Published var selection: FamilyActivitySelection {
        didSet {
            save()
            if isBlocking { applyShield() }
        }
    }

    private let store = ManagedSettingsStore()
    private let selectionKey = "selection"
    private let blockingKey = "isBlocking"

    init() {
        if let data = UserDefaults.standard.data(forKey: selectionKey),
           let saved = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            selection = saved
        } else {
            selection = FamilyActivitySelection()
        }
        isBlocking = UserDefaults.standard.bool(forKey: blockingKey)
    }

    var hasSelection: Bool { !selection.applicationTokens.isEmpty }

    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            print("Screen Time authorization failed: \(error)")
        }
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    func setBlocking(_ on: Bool) {
        isBlocking = on
        UserDefaults.standard.set(on, forKey: blockingKey)
        if on { applyShield() } else { store.clearAllSettings() }
    }

    private func applyShield() {
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
    }

    private func save() {
        if let data = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: selectionKey)
        }
    }
}
