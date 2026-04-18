import Foundation

@MainActor protocol CloudStoring {
    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T?
    func save<T: Encodable>(_ value: T, forKey key: String)
    func addExternalChangeObserver(_ handler: @escaping @MainActor ([String]) -> Void)
}

/// Wraps `NSUbiquitousKeyValueStore` with Codable load/save and a single
/// external-change observer that forwards the list of changed keys.
@MainActor final class CloudStore: CloudStoring {
    static let shared = CloudStore()

    private let kvs: NSUbiquitousKeyValueStore
    private var handlers: [@MainActor ([String]) -> Void] = []

    init(kvs: NSUbiquitousKeyValueStore = .default) {
        self.kvs = kvs
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangeExternally(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvs
        )
        kvs.synchronize()
    }

    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = kvs.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        kvs.set(data, forKey: key)
        kvs.synchronize()
    }

    func addExternalChangeObserver(_ handler: @escaping @MainActor ([String]) -> Void) {
        handlers.append(handler)
    }

    @objc private func didChangeExternally(_ note: Notification) {
        let keys = note.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
        Task { @MainActor in
            for handler in handlers { handler(keys) }
        }
    }
}

/// No-op store for tests and for when iCloud is signed out.
@MainActor final class NoOpCloudStore: CloudStoring {
    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? { nil }
    func save<T: Encodable>(_ value: T, forKey key: String) {}
    func addExternalChangeObserver(_ handler: @escaping @MainActor ([String]) -> Void) {}
}

enum CloudKeys {
    static let settings = "hideAndSeek.settings.v1"
    static let stats = "hideAndSeek.stats.v1"
}
