import SwiftUI

struct PaywallView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    private let benefits: [String] = [
        "Performance graph showing your sharpness over time",
        "Unlock a second bonus exercise each day",
        "Streak and personal-best tracking"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Icon + title
                            VStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(Color.qmCard)
                                        .frame(width: 80, height: 80)
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 36))
                                        .foregroundStyle(Color.qmAccent)
                                }

                                Text("Brain Rep Pro")
                                    .font(.title.weight(.bold))
                                    .foregroundStyle(.primary)

                                Text("\(store.displayPrice) / month. Auto-renews until you cancel.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 8)

                            // Benefits
                            VStack(spacing: 0) {
                                ForEach(Array(benefits.enumerated()), id: \.offset) { idx, benefit in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.qmAccent)
                                            .font(.body)
                                            .padding(.top, 1)
                                        Text(benefit)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                    if idx < benefits.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .qmCard()

                            Spacer(minLength: 8)
                        }
                        .padding(.horizontal)
                    }

                    // CTA area
                    VStack(spacing: 12) {
                        Button {
                            Haptics.tap()
                            Task { await store.purchase() }
                        } label: {
                            Text(store.purchaseInFlight ? "Processing…" : "Unlock Brain Rep Pro")
                                .frame(maxWidth: .infinity)
                        }
                        .prominentButton()
                        .disabled(store.purchaseInFlight)

                        Button {
                            Task { await store.restore() }
                        } label: {
                            Text("Restore Purchase")
                                .frame(maxWidth: .infinity)
                        }
                        .softButton()

                        // Auto-renew disclosure
                        Text("Brain Rep Pro is \(store.displayPrice)/month, billed monthly. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in your Apple Account settings.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            Link("Privacy Policy", destination: URL(string: "https://shimondeitel.github.io/brainrep-site/privacy.html")!)
                        }
                        .font(.caption2)
                        .foregroundStyle(Color.qmAccent)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                    .background(Color(uiColor: .systemBackground))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
        .onChange(of: store.isPro) { _, newValue in
            if newValue { dismiss() }
        }
    }
}
