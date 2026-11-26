import SwiftUI

struct ContentView: View {
    @StateObject private var dns = DNSManager()
    @StateObject private var sub = SubscriptionManager()
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
                    } else if sub.isEntitled {
                        let result = await dns.enable()
                        if result == .registeredNotSelected {
                            showSetupGuide = true
                        }
                    } else {
                        showPlan = true
                    }
                }
            } label: {
                Text(dns.isRegistered ? "広告ブロックOFF" : "広告ブロックON")
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
            Text(sub.statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Text("一部のアプリ内広告はブロックできません。ブロック中に表示できなくなるサイトもあります。その場合は広告ブロックをOFFにしてください。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(24)
        .task {
            await dns.refresh()
            await sub.load()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await dns.refresh()
                    await sub.refreshEntitlement()
                }
            }
        }
        .alert("あと1ステップで有効になります", isPresented: $showSetupGuide) {
            Button("OK") {}
        } message: {
            Text("設定アプリを開き、「一般」→「VPNとデバイス管理」→「DNS」で「広告さよなら」を選んでください。選ぶまで広告ブロックは始まりません。")
        }
        .sheet(isPresented: $showPlan) {
            PlanView(sub: sub) { showPlan = false }
        }
    }
}

struct PlanView: View {
    @ObservedObject var sub: SubscriptionManager
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("月額プラン")
                .font(.title2.bold())
            Text(sub.statusText)
                .foregroundStyle(.secondary)
            if sub.isEntitled {
                Text("広告ブロックが使えます")
            } else {
                Text("1週間無料、その後 月額\(sub.product?.displayPrice ?? "¥100")")
                    .font(.headline)
                Button {
                    Task {
                        if await sub.purchase() { onClose() }
                    }
                } label: {
                    Text(sub.isPurchasing ? "処理中…" : "無料で始める")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(sub.isPurchasing || sub.product == nil)
                Button("購入を復元する") {
                    Task { await sub.restore() }
                }
            }
            HStack(spacing: 24) {
                Link("利用規約", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula")!)
                Link("プライバシーポリシー", destination: URL(string: "https://onejpkey.com/koukoku-privacy.html")!)
            }
            .font(.footnote)
            Button("閉じる") { onClose() }
                .padding(.top, 8)
        }
        .padding(32)
    }
}
