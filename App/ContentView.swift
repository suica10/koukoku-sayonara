import SwiftUI

struct ContentView: View {
    @StateObject private var dns = DNSManager()
    @State private var showPlan = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("広告さよなら")
                .font(.largeTitle.bold())
            Text(dns.statusText)
                .foregroundStyle(.secondary)
            Button {
                Task { dns.isEnabled ? await dns.disable() : await dns.enable() }
            } label: {
                Text(dns.isEnabled ? "DNSを解除する" : "DNSを登録する")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.borderedProminent)
            Button {
                showPlan = true
            } label: {
                Text("課金する")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .padding(24)
        .task { await dns.refresh() }
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
