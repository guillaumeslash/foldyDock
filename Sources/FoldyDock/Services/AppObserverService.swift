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
    private var syncTimer: Timer?

    public init() {
        refreshRunningApps()
        setupNotificationObservers()
        startPeriodicSync()
    }

    deinit {
        syncTimer?.invalidate()
    }

    /// Refresh the list of currently running regular applications
    public func refreshRunningApps() {
        let apps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        self.runningBundleIds = Set(apps.compactMap(\.bundleIdentifier))
        self.activeAppBundleId = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let previousBids = self.runningBundleIds
                self.refreshRunningApps()
                let removedBids = previousBids.subtracting(self.runningBundleIds)
                for bid in removedBids {
                    self.onAppTerminated?(bid)
                }
            }
        }
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

        // On termination: do NOT filter by activationPolicy (.regular) because a terminating or dead
        // process often no longer reports .regular or has transitioned to .prohibited.
        center.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
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
        if matchingApps.isEmpty {
            // Already dead: immediately clean up tracking
            self.runningBundleIds.remove(bundleIdentifier)
            self.onAppTerminated?(bundleIdentifier)
            return
        }

        for app in matchingApps {
            let initiated = app.terminate()
            // If graceful terminate failed or app is stubborn (e.g. background continuity app), force terminate
            if !initiated || !app.isTerminated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if !app.isTerminated {
                        app.forceTerminate()
                    }
                }
            }
        }

        // Clean up from tracking set immediately so UI reflects termination
        self.runningBundleIds.remove(bundleIdentifier)
        self.onAppTerminated?(bundleIdentifier)
    }

    /// Checks if a given bundle ID is running
    public func isRunning(bundleIdentifier: String?) -> Bool {
        guard let bid = bundleIdentifier else { return false }
        return runningBundleIds.contains(bid)
    }
}
