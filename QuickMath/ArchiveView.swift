import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                ScrollView {
                    VStack(spacing: 24) {

                        // Streak + stats
                        HStack(spacing: 16) {
                            MetricTile(value: "\(appModel.streakDays)", label: "Streak")
                            MetricTile(value: "\(personalBest)", label: "Best Score")
                            MetricTile(value: "\(totalCorrect)", label: "Total Correct")
                        }

                        // Performance chart
                        if !appModel.allPerformance.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Sharpness Over Time")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                Chart {
                                    ForEach(Array(chartData.enumerated()), id: \.offset) { idx, entry in
                                        LineMark(
                                            x: .value("Day", idx),
                                            y: .value("Score", entry.score)
                                        )
                                        .foregroundStyle(Color.qmAccent)
                                        .interpolationMethod(.catmullRom)

                                        AreaMark(
                                            x: .value("Day", idx),
                                            yStart: .value("Base", 0),
                                            yEnd: .value("Score", entry.score)
                                        )
                                        .foregroundStyle(Color.qmAccent.opacity(0.12))
                                        .interpolationMethod(.catmullRom)
                                    }
                                }
                                .frame(height: 180)
                                .chartYScale(domain: 0...100)
                                .chartXAxis(.hidden)
                            }
                            .qmCard()
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.largeTitle)
                                    .foregroundStyle(Color.qmAccent)
                                Text("Complete exercises to see your trend")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .qmCard()
                        }

                        // Recent exercises
                        if !appModel.allRecords.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Exercises")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)

                                ForEach(appModel.allRecords.prefix(10), id: \.id) { rec in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(rec.type.capitalized)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.primary)
                                            Text(shortDate(rec.dateServed))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        HStack(spacing: 6) {
                                            Text("\(rec.secondsTaken)s")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Image(systemName: rec.solvedCorrectly ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundStyle(rec.solvedCorrectly ? Color.qmCorrect : Color.qmWrong)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    if rec.id != appModel.allRecords.prefix(10).last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .qmCard()
                        }

                        // Accuracy by type
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Accuracy by Type")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                            HStack(spacing: 12) {
                                ForEach(["logic", "memory", "pattern"], id: \.self) { t in
                                    let pct = accuracy(for: t)
                                    VStack(spacing: 4) {
                                        Text("\(pct)%")
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(pct >= 60 ? Color.qmCorrect : Color.qmWrong)
                                        Text(t.capitalized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.qmCard2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                        }
                        .qmCard()

                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
    }

    // MARK: - Computed

    private var chartData: [PerformanceEntry] {
        Array(appModel.allPerformance.reversed().suffix(30))
    }

    private var personalBest: Int {
        appModel.allPerformance.map(\.score).max() ?? 0
    }

    private var totalCorrect: Int {
        appModel.allRecords.filter(\.solvedCorrectly).count
    }

    private func accuracy(for type: String) -> Int {
        let typed = appModel.allRecords.filter { $0.type == type }
        guard !typed.isEmpty else { return 0 }
        let correct = typed.filter(\.solvedCorrectly).count
        return Int((Double(correct) / Double(typed.count)) * 100)
    }

    private func shortDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }
}
