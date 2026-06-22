import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("quickmath.theme") private var themeRaw = AppTheme.system.rawValue
    @State private var showPaywall = false
    @State private var showDeleteConfirm = false

    private var theme: AppTheme {
        get { AppTheme(rawValue: themeRaw) ?? .system }
        nonmutating set { themeRaw = newValue.rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                List {
                    // Pro status
                    Section("Subscription") {
                        if store.isPro {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Color.qmAccent)
                                Text("Brain Rep Pro — Active")
                                    .foregroundStyle(.primary)
                            }
                            Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                                HStack {
                                    Text("Manage Subscription")
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(Color.qmAccent)
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(Color.qmAccent)
                                    Text("Unlock Brain Rep Pro")
                                        .foregroundStyle(Color.qmAccent)
                                }
                            }
                        }

                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text("Restore Purchase")
                                .foregroundStyle(Color.qmAccent)
                        }
                    }

                    // Appearance
                    Section("Appearance") {
                        Picker("Theme", selection: $themeRaw) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.label).tag(t.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Links
                    Section("Legal") {
                        Link(destination: URL(string: "https://shimondeitel.github.io/brainrep-site/privacy.html")!) {
                            HStack {
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)

                        Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                            HStack {
                                Text("Terms of Use")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }

                    // Data
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete All Data")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
        .confirmationDialog("Delete all exercise history?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete All", role: .destructive) {
                appModel.deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }
}
