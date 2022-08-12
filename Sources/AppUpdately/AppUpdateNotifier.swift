import Foundation
import SwiftUI
import Combine

/// An instance taking care of presenting a new update.
public protocol AppUpdatePresenter {

    /// Will be called when an available update should be presented to
    /// the user.
    /// This method is only called once per version to prevent update spam.
    /// - Returns: `true` if presenting succeeded. You can return `false` if you want to postpone the app update presentation.
    func presentUpdate(for version: String, storeURL: URL) -> Bool
}

/// Monitoring for app updates and automatically refresh the status
/// whenever the app becomes active.
///
/// Checks only once per day.
public final class AppUpdateNotifier: ObservableObject {

    public static let standard = AppUpdateNotifier(userDefaults: .standard)

    /// The last known status. Defaults to `upToDate`.
    @Published
    public private(set) var lastStatus: UpdateStatusFetcher.Status = .upToDate

    private let userDefaults: UserDefaults

    /// The last time a fetch was made.
    private var lastFetch: Date?

    /// The last time we notified. Defaults to a very old date.
    private var lastNotify: Date {
        get {
            let timeInterval = userDefaults.double(forKey: "app_updately_last_notify")
            return Date(timeIntervalSince1970: timeInterval)
        }
        set {
            userDefaults.set(newValue.timeIntervalSince1970, forKey: "app_updately_last_notify")
        }
    }
    private lazy var fetcher: UpdateStatusFetcher = UpdateStatusFetcher()
    private var cancellable: AnyCancellable?

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    /// Fetches the status if allowed to fetch. Only one fetch per day takes place.
    public func updateStatusIfNeeded() {
        guard allowedToFetch() else { return }
        lastFetch = Date()
        cancellable = fetcher.fetch { result in
            guard let status = try? result.get() else {
                return
            }
            DispatchQueue.main.async {
                self.lastStatus = status
            }
        }
    }

    /// Can be used to trigger a presenter if the user didn't see an update view for the available update yet.
    public func triggerPresenterIfNeeded(updatePresenter: AppUpdatePresenter) {
        guard case let UpdateStatusFetcher.Status.updateAvailable(version, storeURL) = lastStatus else {
            return
        }

        let userDefaultsKey = "app_updately_notified_\(version)"
        let didNotifyForVersion = userDefaults.bool(forKey: userDefaultsKey)
        guard !didNotifyForVersion else { return }
        guard updatePresenter.presentUpdate(for: version, storeURL: storeURL) else { return }
        userDefaults.set(true, forKey: userDefaultsKey)
    }

    private func allowedToFetch() -> Bool {
        guard let lastFetch = lastFetch else {
            return true
        }
        return lastFetch < Date().addingTimeInterval(-86000) // -1 day
    }
}
