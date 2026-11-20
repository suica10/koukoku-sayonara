import Foundation
import NetworkExtension

@MainActor
final class DNSManager: ObservableObject {
    @Published var isEnabled = false
    @Published var statusText = "未設定"

    // DoH endpoint (per-user token is appended as the path client ID)
    static let dohURL = URL(string: "https://share.onejpkey.com/dns-query/\(AppConfig.dohToken)")!
    static let dohBootstrap = ["161.33.1.120"]

    func refresh() async {
        let manager = NEDNSSettingsManager.shared()
        do {
            try await manager.loadFromPreferences()
            isEnabled = manager.dnsSettings != nil
            statusText = isEnabled ? "広告ブロック中" : "未設定"
        } catch {
            statusText = "状態を取得できませんでした"
        }
    }

    func enable() async {
        let manager = NEDNSSettingsManager.shared()
        do {
            try await manager.loadFromPreferences()
            let doh = NEDNSOverHTTPSSettings(servers: Self.dohBootstrap)
            doh.serverURL = Self.dohURL
            manager.dnsSettings = doh
            manager.onDemandRules = [NEOnDemandRuleConnect()]
            try await manager.saveToPreferences()
            isEnabled = true
            statusText = "広告ブロック中"
        } catch {
            statusText = "登録に失敗しました: \(error.localizedDescription)"
        }
    }

    func disable() async {
        let manager = NEDNSSettingsManager.shared()
        do {
            try await manager.loadFromPreferences()
            manager.dnsSettings = nil
            try await manager.saveToPreferences()
            isEnabled = false
            statusText = "未設定"
        } catch {
            statusText = "解除に失敗しました: \(error.localizedDescription)"
        }
    }
}
