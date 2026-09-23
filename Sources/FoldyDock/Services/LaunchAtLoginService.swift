import Foundation
import ServiceManagement

public protocol LaunchAtLoginProviding: Sendable {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) -> Bool
}

public final class SMAppLaunchAtLoginProvider: LaunchAtLoginProviding, @unchecked Sendable {
    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
            return true
        } catch {
            print("[LaunchAtLogin] Failed to change state to \(enabled): \(error)")
            return false
        }
    }
}
