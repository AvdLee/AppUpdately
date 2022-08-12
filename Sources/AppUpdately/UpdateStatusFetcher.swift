import Combine
import Foundation

/// Fetches the latest update using a lookup and compares it to
/// the current app version.
/// A status is returned based on comparing both versions.
public struct UpdateStatusFetcher {
    public enum Status: Equatable {
        /// The current app version is newer than the latest App Store.
        case newerVersion
        case upToDate
        case updateAvailable(version: String, storeURL: URL)
    }

    public enum FetchError: LocalizedError {
        case metadata
        case bundleShortVersion

        public var errorDescription: String? {
            switch self {
            case .metadata:
                return "Metadata could not be found"
            case .bundleShortVersion:
                return "Bundle short version could not be found"
            }
        }
    }

    let url: URL
    private let bundleIdentifier: String
    private let decoder: JSONDecoder = JSONDecoder()
    private let urlSession: URLSession

    var currentVersionProvider: () -> String? = {
        if let debugVersion = ProcessInfo.processInfo.environment["AppUpdatelyDebugVersion"] {
            return debugVersion
        }
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    public init(bundleIdentifier: String = Bundle.main.bundleIdentifier!, urlSession: URLSession = .shared) {
        url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)")!
        self.bundleIdentifier = bundleIdentifier
        self.urlSession = urlSession
    }

    public func fetch(_ completion: @escaping (Result<Status, Error>) -> Void) -> AnyCancellable {
        urlSession
            .dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AppMetadataResults.self, decoder: decoder)
            .tryMap({ metadataResults -> Status in
                guard let appMetadata = metadataResults.results.first else {
                    throw FetchError.metadata
                }
                return try updateStatus(for: appMetadata)
            })
            .sink { completionStatus in
                switch completionStatus {
                case .failure(let error):
                    print("Update status fetching failed: \(error)")
                    completion(.failure(error))
                case .finished:
                    break
                }
            } receiveValue: { status in
                print("Update status is \(status)")
                completion(.success(status))
            }
    }

    @available(iOS 15.0, *)
    @available(macOS 12.0, *)
    public func fetch() async throws -> Status {
        let data = try await urlSession.data(from: url).0
        let metadataResults = try decoder.decode(AppMetadataResults.self, from: data)
        guard let appMetadata = metadataResults.results.first else {
            throw FetchError.metadata
        }
        return try updateStatus(for: appMetadata)
    }

    private func updateStatus(for appMetadata: AppMetadata) throws -> Status {
        guard let currentVersion = currentVersionProvider() else {
            throw UpdateStatusFetcher.FetchError.bundleShortVersion
        }

        switch currentVersion.compare(appMetadata.version) {
        case .orderedDescending:
            return UpdateStatusFetcher.Status.newerVersion
        case .orderedSame:
            return UpdateStatusFetcher.Status.upToDate
        case .orderedAscending:
            return UpdateStatusFetcher.Status.updateAvailable(version: appMetadata.version, storeURL: appMetadata.trackViewUrl)
        }
    }
}
