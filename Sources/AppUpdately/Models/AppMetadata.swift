import Foundation

// A list of App metadata with details around a given app.
struct AppMetadata: Codable {
    /// The URL pointing to the App Store Page.
    /// E.g: https://apps.apple.com/br/app/rocketsim-for-xcode/id1504940162?mt=12&uo=4
    let trackViewUrl: URL

    /// The current latest version available in the App Store.
    let version: String
}
