import SwiftUI

struct ContentView: View {
    @StateObject private var dns = DNSManager()
    @State private var showPlan = false
    @State private var showSetupGuide = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("広告さよなら")
                .font(.largeTitle.bold())
            Text(dns.statusText)
                .foregroundStyle(.secondary)
            Button {
                Task {
                    if dns.isRegistered {
                        await dns.disable()
                    } else {
                        let result = await dns.enable()
                        if result == .registeredNotSelected {
                            showSetupGuide = true
                        }
                    }
                }
            } label: {
                Text(dns.isRegistered ? "DNSを解除する" : "DNSを登録する")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.borderedProminent)
            if dns.state == .registeredNotSelected {
                Button("設定方法を見る") { showSetupGuide = true }
            }
            Button {
                showPlan = true
            } label: {
                Text("課金する")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.bordered)
            Text("一部のアプリ内広告はブロックできません。ブロック中に表示できなくなるサイトもあります。その場合はDNSを解除してください。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24)
        .task { await dns.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await dns.refresh() } }
        }
        .alert("あと1ステップで有効になります", isPresented: $showSetupGuide) {
            Button("OK") {}
        } message: {
            Text("設定アプリを開き、「一般」→「VPNとデバイス管理」→「DNS」で「広告さよなら」を選んでください。選ぶまで広告ブロックは始まりません。")
        }
        .sheet(isPresented: $showPlan) {
            VStack(spacing: 16) {
                Text("プランは準備中です")
                    .font(.headline)
                Button("閉じる") { showPlan = false }
            }
            .padding(32)
        }
    }
}
