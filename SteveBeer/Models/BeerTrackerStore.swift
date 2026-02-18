import Foundation

@MainActor
final class BeerTrackerStore: ObservableObject {
    @Published var startDate: Date {
        didSet {
            save()
        }
    }

    @Published private(set) var entries: [BeerEntry] {
        didSet {
            save()
        }
    }

    private var entriesSinceStartDate: [BeerEntry] {
        let cutoff = Calendar.current.startOfDay(for: startDate)
        return entries.filter { $0.date >= cutoff }
    }

    var totalBeers: Int {
        entriesSinceStartDate.reduce(0) { $0 + $1.amount }
    }

    var totalTallBeers: Int {
        entriesSinceStartDate
            .filter { $0.type == .tall }
            .reduce(0) { $0 + $1.amount }
    }

    var totalNormalBeers: Int {
        entriesSinceStartDate
            .filter { $0.type == .normal }
            .reduce(0) { $0 + $1.amount }
    }

    var trackedDaysCount: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(entriesSinceStartDate.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    var averageBeersPerTrackedDay: Double {
        guard trackedDaysCount > 0 else { return 0 }
        return Double(totalBeers) / Double(trackedDaysCount)
    }

    var todaysTallBeers: Int {
        amountToday(for: .tall)
    }

    var todaysNormalBeers: Int {
        amountToday(for: .normal)
    }

    var todaysTotalBeers: Int {
        entriesSinceStartDate
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    private let fileManager: FileManager
    private let fileName = "beer-tracker-data.json"

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        if let saved = Self.load(fileManager: fileManager) {
            startDate = saved.startDate
            entries = saved.entries
            // Persist loaded data so older files (without entry IDs) are migrated on launch.
            save()
        } else {
            startDate = Calendar.current.startOfDay(for: Date())
            entries = []
            save()
        }
    }

    @discardableResult
    func addEntry(type: BeerType, amount: Int) -> BeerEntry {
        let safeAmount = max(1, amount)
        let newEntry = BeerEntry(date: Date(), type: type, amount: safeAmount)
        entries.append(newEntry)
        return newEntry
    }

    @discardableResult
    func removeEntries(withIDs ids: Set<UUID>) -> Int {
        let originalCount = entries.count
        entries.removeAll { ids.contains($0.id) }
        return originalCount - entries.count
    }

    func resetTracking() {
        startDate = Calendar.current.startOfDay(for: Date())
        entries = []
    }

    private func amountToday(for type: BeerType) -> Int {
        entriesSinceStartDate
            .filter { Calendar.current.isDateInToday($0.date) && $0.type == type }
            .reduce(0) { $0 + $1.amount }
    }

    private var fileURL: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent(fileName)
    }

    private func save() {
        guard let fileURL else { return }

        do {
            let data = TrackerData(startDate: startDate, entries: entries)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let encoded = try encoder.encode(data)
            try encoded.write(to: fileURL, options: .atomic)
        } catch {
            // For v1 we silently ignore save errors so the app remains usable.
            // In a production app, this should be surfaced to the user.
            print("Failed to save tracker data: \(error)")
        }
    }

    private static func load(fileManager: FileManager) -> TrackerData? {
        guard let fileURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("beer-tracker-data.json") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(TrackerData.self, from: data)
        } catch {
            return nil
        }
    }
}
