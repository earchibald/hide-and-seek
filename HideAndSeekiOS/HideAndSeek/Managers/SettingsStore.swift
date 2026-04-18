import Foundation

/// Persists `GameSettings` to a local UserDefaults cache and to iCloud KVS.
/// Remote changes overwrite local (last-writer-wins) and fire `onRemoteChange`.
@MainActor final class SettingsStore {
    private let defaults: UserDefaults
    private let cloud: CloudStoring
    private let userDefaultsKey = "hideAndSeek.settings"

    private(set) var settings: GameSettings
    var onRemoteChange: ((GameSettings) -> Void)?

    init(defaults: UserDefaults = .standard, cloud: CloudStoring = CloudStore.shared) {
        self.defaults = defaults
        self.cloud = cloud

        let local: GameSettings
        if let data = defaults.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode(GameSettings.self, from: data) {
            local = decoded
        } else {
            local = GameSettings()
        }

        if let remote = cloud.load(GameSettings.self, forKey: CloudKeys.settings) {
            self.settings = remote
        } else {
            self.settings = local
        }
        persist()

        cloud.addExternalChangeObserver { [weak self] keys in
            guard let self, keys.contains(CloudKeys.settings) else { return }
            guard let remote = self.cloud.load(GameSettings.self, forKey: CloudKeys.settings) else { return }
            self.settings = remote
            if let encoded = try? JSONEncoder().encode(remote) {
                self.defaults.set(encoded, forKey: self.userDefaultsKey)
            }
            self.onRemoteChange?(remote)
        }
    }

    func update(_ new: GameSettings) {
        guard new != settings else { return }
        settings = new
        persist()
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: userDefaultsKey)
        }
        cloud.save(settings, forKey: CloudKeys.settings)
    }
}
