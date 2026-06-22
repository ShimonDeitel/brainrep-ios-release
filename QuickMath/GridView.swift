import SwiftUI

struct GridView: View {
    let exercise: ExerciseBank.Exercise
    let isBonus: Bool

    @EnvironmentObject var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var userAnswer: String = ""
    @State private var phase: Phase = .reading
    @State private var startTime: Date = Date()
    @State private var elapsed: Int = 0
    @State private var timer: Timer?
    @State private var showResult: Bool = false
    @State private var wasCorrect: Bool = false
    @State private var timerCount: Int = 5
    @State private var memCountdown: Timer?

    enum Phase {
        case reading     // user reads the question
        case answering   // user types / confirms answer
        case result      // reveal correct/wrong
    }

    var body: some View {
        NavigationStack {
            ZStack {
                QMBackground()
                VStack(spacing: 28) {
                    // Type badge
                    Text(exercise.type.rawValue.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(Color.qmAccent)
                        .padding(.top, 8)

                    // Prompt card
                    promptSection

                    if phase == .answering {
                        answerSection
                    }

                    if phase == .result {
                        resultSection
                    }

                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle(isBonus ? "Bonus Exercise" : "Today's Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.qmAccent)
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            memCountdown?.invalidate()
        }
    }

    // MARK: - Prompt section

    @ViewBuilder
    private var promptSection: some View {
        VStack(spacing: 12) {
            if phase == .reading {
                Text(exercise.prompt)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                if exercise.type == .memory {
                    VStack(spacing: 8) {
                        Text("Memorise, then tap Ready (\(timerCount)s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ProgressView(value: Double(5 - timerCount), total: 5)
                            .tint(Color.qmAccent)
                    }
                }

                Button("Ready") {
                    startAnswering()
                }
                .prominentButton()
                .onAppear { startMemoryCountdown() }
            } else {
                Text(exercise.type == .memory ? "Now recall the sequence:" : exercise.prompt)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    // MARK: - Answer section

    @ViewBuilder
    private var answerSection: some View {
        VStack(spacing: 16) {
            TextField("Your answer", text: $userAnswer)
                .textFieldStyle(.plain)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .autocorrectionDisabled()

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("\(elapsed)s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Check Answer") {
                checkAnswer()
            }
            .prominentButton()
            .disabled(userAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    // MARK: - Result section

    @ViewBuilder
    private var resultSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Image(systemName: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(wasCorrect ? Color.qmCorrect : Color.qmWrong)
                Text(wasCorrect ? "Correct!" : "Not quite")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                if !wasCorrect {
                    VStack(spacing: 4) {
                        Text("The answer was:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(exercise.answer)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                }
                Text("Completed in \(elapsed) seconds")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.qmCard, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button("Done") {
                dismiss()
            }
            .prominentButton()
        }
    }

    // MARK: - Logic

    private func startMemoryCountdown() {
        guard exercise.type == .memory else { return }
        timerCount = 5
        memCountdown = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            if timerCount > 0 {
                timerCount -= 1
            } else {
                t.invalidate()
                startAnswering()
            }
        }
    }

    private func startAnswering() {
        memCountdown?.invalidate()
        phase = .answering
        startTime = Date()
        elapsed = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed = Int(Date().timeIntervalSince(startTime))
        }
        Haptics.tap()
    }

    private func checkAnswer() {
        timer?.invalidate()
        elapsed = Int(Date().timeIntervalSince(startTime))
        let normalized = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let correctNorm = exercise.answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        wasCorrect = normalized == correctNorm || correctNorm.contains(normalized) && normalized.count > 3
        phase = .result
        appModel.markExercise(exercise, correct: wasCorrect, seconds: elapsed)
        if wasCorrect {
            Haptics.success()
        } else {
            Haptics.warning()
        }
    }
}
