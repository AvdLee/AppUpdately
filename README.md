# AppUpdately

Fetch the update status for a given app bundle identifier, without the need of any remote configuration. Simply provide your app's bundle identifier and compare the resulting update status.

Supports macOS and iOS.

## Usage

The fetcher automatically fetches the bundle identifier. You can use the following code example:

```swift
var cancellable: AnyCancellable?
cancellable = UpdateStatusFetcher().fetch { result in
    defer { cancellable?.cancel() }
    guard let status = try? result.get() else { return }

    switch status {
    case .upToDate:
        break
    case .updateAvailable(let version, let storeURL):
        // Use the information to present your update alert or view.
    }
}
```

Or with [async/await](https://www.avanderlee.com/swift/async-await/):

```swift
Task {
    let fetcher = UpdateStatusFetcher()
    let status = try await fetcher.fetch()
    
    switch status {
    case .upToDate:
        break
    case .updateAvailable(let version, let storeURL):
        // Use the information to present your update alert or view.
    }
}
```

## Installation
### Swift Package Manager

Add `https://github.com/AvdLee/AppUpdately.git` within Xcode's package manager.

#### Manifest File

Add AppUpdately as a package to your `Package.swift` file and then specify it as a dependency of the Target in which you wish to use it.

```swift
import PackageDescription

let package = Package(
    name: "MyProject",
    platforms: [
       .macOS(.v10_15)
       .iOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/AvdLee/AppUpdately.git", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "MyProject",
            dependencies: ["AppUpdately"]),
        .testTarget(
            name: "MyProjectTests",
            dependencies: ["MyProject"]),
    ]
)
```

## License

AppUpdately is available under the MIT license. See the LICENSE file for more info.
