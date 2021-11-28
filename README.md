# AppUpdately

Fetch the update status for a given app bundle identifier, without the need of any remote configuration. Simply provide your app's bundle identifier and compare the resulting update status.

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
