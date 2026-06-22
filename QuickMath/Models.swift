import Foundation
import SwiftData

// MARK: - SwiftData Models

@Model
final class ExerciseRecord {
    var id: UUID
    var type: String          // "logic" | "memory" | "pattern"
    var prompt: String
    var answer: String
    var dateServed: Date
    var solvedCorrectly: Bool
    var secondsTaken: Int

    init(id: UUID = UUID(),
         type: String,
         prompt: String,
         answer: String,
         dateServed: Date = Date(),
         solvedCorrectly: Bool = false,
         secondsTaken: Int = 0) {
        self.id = id
        self.type = type
        self.prompt = prompt
        self.answer = answer
        self.dateServed = dateServed
        self.solvedCorrectly = solvedCorrectly
        self.secondsTaken = secondsTaken
    }
}

@Model
final class PerformanceEntry {
    var date: Date
    var score: Int            // 0–100
    var exerciseType: String

    init(date: Date = Date(), score: Int, exerciseType: String) {
        self.date = date
        self.score = score
        self.exerciseType = exerciseType
    }
}

// MARK: - Exercise generator

struct ExerciseBank {
    enum ExerciseType: String, CaseIterable {
        case logic, memory, pattern
    }

    struct Exercise {
        let type: ExerciseType
        let prompt: String
        let answer: String
    }

    // Deterministically pick today's exercise so the same user always gets the same one per day
    static func todaysExercise(date: Date = Date(), bonusOffset: Int = 0) -> Exercise {
        let cal = Calendar.current
        let day = cal.ordinality(of: .day, in: .year, for: date) ?? 1
        let seed = (day + bonusOffset * 97) % exercises.count
        return exercises[seed]
    }

    private static let exercises: [Exercise] = [
        // Logic
        Exercise(type: .logic, prompt: "If all Bloops are Razzles and all Razzles are Lazzles, are all Bloops Lazzles?", answer: "Yes"),
        Exercise(type: .logic, prompt: "A farmer has 17 sheep. All but 9 die. How many sheep does the farmer have left?", answer: "9"),
        Exercise(type: .logic, prompt: "I have two US coins totalling 30 cents. One is not a nickel. What are they?", answer: "Quarter and nickel"),
        Exercise(type: .logic, prompt: "What comes next in the sequence: 2, 4, 8, 16, ?", answer: "32"),
        Exercise(type: .logic, prompt: "There are 3 light switches outside a room. One controls the light inside. How can you find the right one with only one visit?", answer: "Turn one on, warm another, enter and check"),
        Exercise(type: .logic, prompt: "Mary's father has 5 daughters: Nana, Nene, Nini, Nono. What is the fifth daughter's name?", answer: "Mary"),
        Exercise(type: .logic, prompt: "A rooster lays an egg on top of the barn. Which way does it roll?", answer: "Roosters don't lay eggs"),
        Exercise(type: .logic, prompt: "What number comes next: 1, 1, 2, 3, 5, 8, ?", answer: "13"),
        Exercise(type: .logic, prompt: "If you have a 3-litre jug and a 5-litre jug, how do you measure exactly 4 litres?", answer: "Fill 5L, pour into 3L, empty 3L, pour remaining 2L into 3L, fill 5L again, pour 1L into 3L"),
        Exercise(type: .logic, prompt: "John is twice as old as Jane was when John was as old as Jane is now. Their ages add up to 63. How old is John?", answer: "42"),
        // Memory
        Exercise(type: .memory, prompt: "Memorise this sequence then enter it: Circle, Star, Moon, Arrow, Diamond", answer: "Circle Star Moon Arrow Diamond"),
        Exercise(type: .memory, prompt: "Read once then recall: Red, Bus, Seven, Lake, Pencil", answer: "Red Bus Seven Lake Pencil"),
        Exercise(type: .memory, prompt: "Remember these 5 items in order: Piano, Cloud, Tiger, Book, River", answer: "Piano Cloud Tiger Book River"),
        Exercise(type: .memory, prompt: "Recall the sequence: Alpha, Bravo, Charlie, Delta, Echo", answer: "Alpha Bravo Charlie Delta Echo"),
        Exercise(type: .memory, prompt: "Remember: 7, 3, 9, 1, 5, 4", answer: "7 3 9 1 5 4"),
        Exercise(type: .memory, prompt: "Memorise: Lamp, Fog, Needle, Brick, Feather", answer: "Lamp Fog Needle Brick Feather"),
        Exercise(type: .memory, prompt: "Recall these colours: Crimson, Teal, Amber, Slate, Lavender", answer: "Crimson Teal Amber Slate Lavender"),
        Exercise(type: .memory, prompt: "Remember: Monkey, Umbrella, Trumpet, Pebble, Candle", answer: "Monkey Umbrella Trumpet Pebble Candle"),
        // Pattern
        Exercise(type: .pattern, prompt: "What completes the pattern? AZ, BY, CX, D?", answer: "W"),
        Exercise(type: .pattern, prompt: "Find the odd one out: 36, 49, 64, 72, 81", answer: "72"),
        Exercise(type: .pattern, prompt: "What comes next: O, T, T, F, F, S, S, E, ?", answer: "N"),
        Exercise(type: .pattern, prompt: "Complete the analogy: Hot is to Cold as Day is to ?", answer: "Night"),
        Exercise(type: .pattern, prompt: "What is the missing number? 3, 6, 11, 18, 27, ?", answer: "38"),
        Exercise(type: .pattern, prompt: "What comes next: J, F, M, A, M, J, ?", answer: "J"),
        Exercise(type: .pattern, prompt: "Spot the rule: 1, 4, 9, 16, 25. What is the 7th term?", answer: "49"),
        Exercise(type: .pattern, prompt: "What comes next in: Sunday, Monday, Tuesday, ?", answer: "Wednesday"),
        Exercise(type: .pattern, prompt: "Which number is missing? 5, 10, 20, 40, ?, 160", answer: "80"),
        Exercise(type: .pattern, prompt: "What completes the sequence? B, D, F, H, ?", answer: "J"),
    ]
}

// MARK: - AppModel

@MainActor
final class AppModel: ObservableObject {
    let container: ModelContainer
    weak var store: Store?

    @Published private(set) var todaysExercise: ExerciseBank.Exercise
    @Published private(set) var bonusExercise: ExerciseBank.Exercise
    @Published private(set) var todaysRecord: ExerciseRecord?
    @Published private(set) var bonusRecord: ExerciseRecord?
    @Published private(set) var allRecords: [ExerciseRecord] = []
    @Published private(set) var allPerformance: [PerformanceEntry] = []
    @Published private(set) var streakDays: Int = 0

    init(container: ModelContainer) {
        self.container = container
        self.todaysExercise = ExerciseBank.todaysExercise()
        self.bonusExercise = ExerciseBank.todaysExercise(bonusOffset: 1)
        reload()
    }

    static func makeContainer() -> ModelContainer {
        let schema = Schema([ExerciseRecord.self, PerformanceEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return (try? ModelContainer(for: schema, configurations: [fallback])) ?? {
                fatalError("Cannot create ModelContainer: \(error)")
            }()
        }
    }

    func reload() {
        let ctx = container.mainContext
        let records = (try? ctx.fetch(FetchDescriptor<ExerciseRecord>(sortBy: [SortDescriptor(\.dateServed, order: .reverse)]))) ?? []
        let perf = (try? ctx.fetch(FetchDescriptor<PerformanceEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))) ?? []
        allRecords = records
        allPerformance = perf
        let today = Calendar.current.startOfDay(for: Date())
        todaysRecord = records.first { Calendar.current.startOfDay(for: $0.dateServed) == today && $0.type == ExerciseBank.todaysExercise().type }
        bonusRecord = records.first { Calendar.current.startOfDay(for: $0.dateServed) == today && $0.type == ExerciseBank.todaysExercise(bonusOffset: 1).type && $0.id != todaysRecord?.id }
        streakDays = computeStreak(records: records)
    }

    func refresh() { reload() }

    func markExercise(_ exercise: ExerciseBank.Exercise, correct: Bool, seconds: Int) {
        let ctx = container.mainContext
        let rec = ExerciseRecord(type: exercise.type.rawValue,
                                 prompt: exercise.prompt,
                                 answer: exercise.answer,
                                 dateServed: Date(),
                                 solvedCorrectly: correct,
                                 secondsTaken: seconds)
        ctx.insert(rec)
        let score = correct ? max(100 - seconds, 10) : 0
        let perf = PerformanceEntry(score: score, exerciseType: exercise.type.rawValue)
        ctx.insert(perf)
        try? ctx.save()
        reload()
    }

    func deleteAllData() {
        let ctx = container.mainContext
        try? ctx.delete(model: ExerciseRecord.self)
        try? ctx.delete(model: PerformanceEntry.self)
        try? ctx.save()
        reload()
    }

    private func computeStreak(records: [ExerciseRecord]) -> Int {
        guard !records.isEmpty else { return 0 }
        let cal = Calendar.current
        var days = Set<Date>()
        for r in records where r.solvedCorrectly {
            days.insert(cal.startOfDay(for: r.dateServed))
        }
        var streak = 0
        var check = cal.startOfDay(for: Date())
        while days.contains(check) {
            streak += 1
            check = cal.date(byAdding: .day, value: -1, to: check)!
        }
        return streak
    }
}
