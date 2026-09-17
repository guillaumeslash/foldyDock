import Foundation
import AppKit

public struct InstalledApp: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let bundleIdentifier: String?
    public let url: URL
    public var path: String { url.path }

    public init(name: String, bundleIdentifier: String?, url: URL) {
        self.id = bundleIdentifier ?? url.path
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.url = url
    }
}

@MainActor
public final class AppDiscoveryService: ObservableObject {
    public static let shared = AppDiscoveryService()

    @Published public private(set) var installedApps: [InstalledApp] = []
    @Published public private(set) var isLoading: Bool = false

    private var hasLoaded: Bool = false

    public init() {
        refreshApps()
    }

    public func refreshApps(force: Bool = false) {
        if hasLoaded && !force { return }
        isLoading = true

        Task.detached(priority: .userInitiated) {
            let apps = Self.scanInstalledApps()
            await MainActor.run {
                self.installedApps = apps
                self.isLoading = false
                self.hasLoaded = true
            }
        }
    }

    nonisolated public static func scanInstalledApps() -> [InstalledApp] {
        let candidateDirs = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/Applications/Utilities"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        var apps: [InstalledApp] = []
        var seenPaths = Set<String>()
        var seenBundleIds = Set<String>()
        let fm = FileManager.default

        for dir in candidateDirs {
            guard let contents = try? fm.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for fileUrl in contents {
                if fileUrl.pathExtension == "app" {
                    let path = fileUrl.path
                    guard !seenPaths.contains(path) else { continue }
                    seenPaths.insert(path)

                    let bundle = Bundle(url: fileUrl)
                    let bundleId = bundle?.bundleIdentifier
                    if let bid = bundleId {
                        guard !seenBundleIds.contains(bid) else { continue }
                        seenBundleIds.insert(bid)
                    }

                    let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                        ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                        ?? fm.displayName(atPath: path).replacingOccurrences(of: ".app", with: "")

                    apps.append(InstalledApp(
                        name: displayName,
                        bundleIdentifier: bundleId,
                        url: fileUrl
                    ))
                }
            }
        }

        apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return apps
    }
}
