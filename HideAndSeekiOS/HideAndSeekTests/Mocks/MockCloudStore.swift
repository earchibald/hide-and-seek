import Foundation
@testable import HideAndSeek

@MainActor final class MockCloudStore: CloudStoring {
    var storage: [String: Data] = [:]
    private var observers: [@MainActor ([String]) -> Void] = []

    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = storage[key] else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        storage[key] = data
    }

    func addExternalChangeObserver(_ handler: @escaping @MainActor ([String]) -> Void) {
        observers.append(handler)
    }

    /// Simulate a remote write landing locally via iCloud.
    func simulateExternalChange<T: Encodable>(_ value: T, forKey key: String) {
        save(value, forKey: key)
        for handler in observers { handler([key]) }
    }
}
