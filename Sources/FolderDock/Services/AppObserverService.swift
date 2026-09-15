import AppKit
import Combine

@MainActor
public final class AppObserverService: ObservableObject {
    public static let shared = AppObserverService()

    @Published public private(set) var runningBundleIds: Set<String> = []
    @Published public private(set) var activeAppBundleId: String?

    /// Callbacks for ViewModel to react to unpinned apps
    public var onAppLaunched: ((NSRunningApplication) -> Void)?
    public var onAppTerminated: ((String) -> Void)?

    private var cancellables = Set<AnyCancellable>()

    public init() {
        refreshRunningApps()
        setupNotificationObservers()
    }

    /// Refresh the list of currently running regular applications
    public func refreshRunningApps() {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        self.runningBundleIds = Set(apps.compactMap(\.bundleIdentifier))
        self.activeAppBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private func setupNotificationObservers() {
        let center = NSWorkspace.shared.notificationCenter

        center.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .filter { $0.activationPolicy == .regular }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] app in
                guard let self = self, let bid = app.bundleIdentifier else { return }
                self.runningBundleIds.insert(bid)
                self.onAppLaunched?(app)
            }
            .store(in: &cancellables)

        center.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .filter { $0.activationPolicy == .regular }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] app in
                guard let self = self, let bid = app.bundleIdentifier else { return }
                self.runningBundleIds.remove(bid)
                self.onAppTerminated?(bid)
            }
            .store(in: &cancellables)

        center.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] app in
                self?.activeAppBundleId = app.bundleIdentifier
            }
            .store(in: &cancellables)
    }

    /// Launches or brings to front an application
    public func launchApp(item: DockItem) {
        var appURL: URL?

        if let path = item.appPath, FileManager.default.fileExists(atPath: path) {
            appURL = URL(fileURLWithPath: path)
        } else if let bid = item.bundleIdentifier {
            appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid)
        }

        guard let targetURL = appURL else {
            print("[AppObserverService] Cannot find application for: \(item.title)")
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        NSWorkspace.shared.openApplication(at: targetURL, configuration: config) { _, error in
            if let error = error {
                print("[AppObserverService] Failed to open \(item.title): \(error.localizedDescription)")
            }
        }
    }

    /// Terminates an application by bundle identifier (used on middle-click or context menu)
    public func terminateApp(bundleIdentifier: String) {
        let matchingApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        for app in matchingApps {
            app.terminate()
        }
    }

    /// Checks if a given bundle ID is running
    public func isRunning(bundleIdentifier: String?) -> Bool {
        guard let bid = bundleIdentifier else { return false }
        return runningBundleIds.contains(bid)
    }
}
