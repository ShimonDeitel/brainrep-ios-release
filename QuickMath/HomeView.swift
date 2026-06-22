import SwiftUI

struct HomeView: View {
    var forceScreen: String? = nil

    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store

    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showInsights = false
    @State private var showExercise = false
    @State private var showBonus = false

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 4) {
                            Text("Brain Rep")
                                .font(.largeTitle.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("Daily mental warm-up")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 8)

                        // Streak banner
                        HStack(spacing: 16) {
                            MetricTile(value: "\(appModel.streakDays)", label: "Day Streak")
                            MetricTile(value: "\(appModel.allRecords.filter(\.solvedCorrectly).count)", label: "Correct")
                            MetricTile(value: "\(appModel.allRecords.count)", label: "Total")
                        }
                        .padding(.horizontal)

                        // Today's exercise card
                        exerciseCard(
                            title: "Today's Exercise",
                            subtitle: appModel.todaysExercise.type.rawValue.capitalized,
                            done: appModel.todaysRecord != nil,
                            correct: appModel.todaysRecord?.solvedCorrectly
                        ) {
                            showExercise = true
                        }
                        .padding(.horizontal)

                        // Pro tile: Bonus exercise + Insights
                        if store.isPro {
                            exerciseCard(
                                title: "Bonus Exercise",
                                subtitle: appModel.bonusExercise.type.rawValue.capitalized,
                                done: appModel.bonusRecord != nil,
                                correct: appModel.bonusRecord?.solvedCorrectly
                            ) {
                                showBonus = true
                            }
                            .padding(.horizontal)

                            Button {
                                showInsights = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Sharpness Insights")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(.primary)
                                        Text("Track your cognitive trend")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.title2)
                                        .foregroundStyle(Color.qmAccent)
                                }
                                .qmCard()
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "lock.fill")
                                                .foregroundStyle(Color.qmAccent)
                                            Text("Brain Rep Pro")
                                                .font(.headline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                        }
                                        Text("Graphs, streaks & a bonus daily exercise")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .qmCard()
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Color.qmAccent)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(store)
                .environmentObject(appModel)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showInsights) {
            InsightsView()
                .environmentObject(appModel)
                .environmentObject(store)
        }
        .sheet(isPresented: $showExercise) {
            GridView(exercise: appModel.todaysExercise, isBonus: false)
                .environmentObject(appModel)
        }
        .sheet(isPresented: $showBonus) {
            GridView(exercise: appModel.bonusExercise, isBonus: true)
                .environmentObject(appModel)
        }
        .onAppear {
            if let s = forceScreen {
                if s == "paywall" { showPaywall = true }
                else if s == "insights" { showInsights = true }
                else if s == "exercise" { showExercise = true }
                else if s == "settings" { showSettings = true }
            }
        }
    }

    @ViewBuilder
    private func exerciseCard(title: String, subtitle: String, done: Bool, correct: Bool?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if done {
                        HStack(spacing: 4) {
                            Image(systemName: (correct == true) ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle((correct == true) ? Color.qmCorrect : Color.qmWrong)
                            Text((correct == true) ? "Completed correctly" : "Completed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                Image(systemName: done ? "checkmark.seal.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(done ? Color.qmCorrect : Color.qmAccent)
            }
            .qmCard()
        }
        .buttonStyle(.plain)
    }
}
