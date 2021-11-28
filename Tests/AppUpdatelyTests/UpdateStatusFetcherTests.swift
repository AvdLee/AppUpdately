import XCTest
@testable import AppUpdately
import Mocker

final class UpdateStatusFetcherTests: XCTestCase {

    private var fetcher: UpdateStatusFetcher!
    private let mockedTrackViewURL = URL(string: "https://apps.apple.com/br/app/rocketsim-for-xcode/id1504940162?mt=12&uo=4")!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockingURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)
        fetcher = UpdateStatusFetcher(bundleIdentifier: "com.swiftlee.rocketsim", urlSession: urlSession)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        fetcher = nil
    }

    func testSameVersion() {
        mock(currentVersion: "2.0.0", latestVersion: "2.0.0")
        XCTAssertStatusEquals(.upToDate)
    }

    func testNewerVersion() {
        mock(currentVersion: "3.0.0", latestVersion: "2.0.0")
        XCTAssertStatusEquals(.upToDate)
    }

    func testOlderVersion() {
        mock(currentVersion: "1.0.0", latestVersion: "2.0.0")
        XCTAssertStatusEquals(.updateAvailable(version: "2.0.0", storeURL: mockedTrackViewURL))
    }

    @available(macOS 12.0, *)
    func testSameVersionAsync() async throws {
        mock(currentVersion: "2.0.0", latestVersion: "2.0.0")
        let status = try await fetcher.fetch()
        XCTAssertEqual(status, .upToDate)
    }

    @available(macOS 12.0, *)
    func testNewerVersionAsync() async throws {
        mock(currentVersion: "3.0.0", latestVersion: "2.0.0")
        let status = try await fetcher.fetch()
        XCTAssertEqual(status, .upToDate)
    }

    @available(macOS 12.0, *)
    func testOlderVersionAsync() async throws {
        mock(currentVersion: "1.0.0", latestVersion: "2.0.0")
        let status = try await fetcher.fetch()
        XCTAssertEqual(status, .updateAvailable(version: "2.0.0", storeURL: mockedTrackViewURL))
    }
}

extension UpdateStatusFetcherTests {
    func XCTAssertStatusEquals(_ expectedStatus: UpdateStatusFetcher.Status, function: String = #function, line: UInt = #line) {
        let expectation = expectation(description: "Status should be fetched")
        let cancellable = fetcher.fetch { result in
            switch result {
            case .success(let status):
                XCTAssertEqual(status, expectedStatus, line: line)
            case .failure(let error):
                XCTFail("Fetching failed with \(error)")
            }
            expectation.fulfill()
        }
        addTeardownBlock {
            cancellable.cancel()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func mock(currentVersion: String, latestVersion: String) {
        fetcher.currentVersionProvider = {
            currentVersion
        }
        Mock(url: fetcher.url, dataType: .json, statusCode: 200, data: [.get: mockedResult(for: latestVersion).jsonData])
            .register()
    }

    func mockedResult(for version: String) -> AppMetadataResults {
        AppMetadataResults(results: [
            .init(trackViewUrl: mockedTrackViewURL, version: version)
        ])
    }
}

public extension Encodable {
    /// Returns a `Data` representation of the current `Encodable` instance to use for mocking purposes. Force unwrapping as it's only used for tests.
    var jsonData: Data {
        let encoder = JSONEncoder()
        return try! encoder.encode(self)
    }
}
