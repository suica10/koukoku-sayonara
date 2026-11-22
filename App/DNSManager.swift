import Foundation
import NetworkExtension

@MainActor
final class DNSManager: ObservableObject {
    enum State {
        case notRegistered          // nothing saved
        case registeredNotSelected  // saved, but iOS Settings still has DNS on "Automatic"
        case active                 // saved and selected in iOS Settings
    }

    @Published var state: State = .notRegistered
    @Published var statusText = "未設定"

    // DoH endpoint (per-user token is appended as the path client ID)
    static let dohURL = URL(string: "https://share.onejpkey.com/dns-query/\(AppConfig.dohToken)")!
    static let dohBootstrap = ["161.33.1.120"]

    var isRegistered: Bool { state != .notRegistered }

    private func applyState(from manager: NEDNSSettingsManager) {
        if manager.dnsSettings == nil {
            state = .notRegistered
            statusText = "未設定"
        } else if manager.isEnabled {
            state = .active
            statusText = "広告ブロック中"
        } else {
            state = .registeredNotSelected
            statusText = "登録済み（設定アプリで選択が必要です）"
        }
    }

    func refresh() async {
        let manager = NEDNSSettingsManager.shared()
        do {
            try await manager.loadFromPreferences()
            applyState(from: manager)
        } catch {
            statusText = "状態を取得できませんでした"
        }
    }

    /// Saves the DNS settings. Returns the state after saving so the caller
    /// can show the "select it in Settings" guidance when needed.
    func enable() async -> State {
        let manager = NEDNSSettingsManager.shared()
        do {
            try await manager.loadFromPreferences()
            let doh = NEDNSOverHTTPSSettings(servers: Self.dohBootstrap)
            doh.serverURL = Self.dohURL
            manager.dnsSettings = doh
            manager.onDemandRules = [NEOnDemandRuleConnect()]
            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
            applyState(from: manager)
        } catch {
            statusText = "登録に失敗しました: \(error.localizedDescription)"
        }
        return state
    }

    func disable() async {
        let manager = NEDNSSettingsManager.shared()
        do {
            // Saving a configuration with dnsSettings == nil is rejected by
            // the system (the on-demand rules from enable() remain attached),
            // which is why the old disable failed. Removal has its own API.
            try await manager.removeFromPreferences()
            state = .notRegistered
            statusText = "未設定"
        } catch {
            statusText = "解除に失敗しました: \(error.localizedDescription)"
        }
    }
}
