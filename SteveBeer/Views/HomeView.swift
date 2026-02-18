import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: BeerTrackerStore

    @State private var tallAmount = 1
    @State private var normalAmount = 1
    @State private var activePour: PourPresentation?
    @State private var toastMessage: String?
    @State private var undoableAction: UndoableAddAction?
    @State private var displayedTotal = 0
    @State private var totalAnimationTask: Task<Void, Never>?
    @State private var toastDismissTask: Task<Void, Never>?

    private var startDateSubtitle: String {
        "Since \(Self.startDateFormatter.string(from: store.startDate))"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    VStack(spacing: 14) {
                        DashboardCard(title: "Total Beers", subtitle: startDateSubtitle) {
                            Text("\(displayedTotal)")
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.65)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [AppTheme.tallAmber, AppTheme.normalGolden],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        DashboardCard(title: "Tracking Start") {
                            DatePicker(
                                "Start Date",
                                selection: $store.startDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()

                            Text(Self.startDateFormatter.string(from: store.startDate))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        AddBeerCard(
                            title: "Add Tall",
                            type: .tall,
                            tint: AppTheme.tallAmber,
                            amount: $tallAmount,
                            buttonTitle: "Add Tall"
                        ) {
                            addBeer(type: .tall, amount: tallAmount)
                            tallAmount = 1
                        }

                        AddBeerCard(
                            title: "Add Normal",
                            type: .normal,
                            tint: AppTheme.normalGolden,
                            amount: $normalAmount,
                            buttonTitle: "Add Normal"
                        ) {
                            addBeer(type: .normal, amount: normalAmount)
                            normalAmount = 1
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .padding(.bottom, 40)
                }

                if let activePour {
                    PourAnimationView(color: activePour.color, label: activePour.label) {
                        self.activePour = nil
                    }
                    .transition(.opacity)
                    .zIndex(2)
                }

                if let toastMessage {
                    VStack {
                        Spacer()
                        ToastView(
                            message: toastMessage,
                            actionTitle: undoableAction == nil ? nil : "Undo",
                            onActionTap: undoableAction == nil ? nil : undoLastAdd
                        )
                            .padding(.bottom, 28)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .zIndex(3)
                }
            }
            .navigationTitle("Beer Counter")
            .onAppear {
                displayedTotal = store.totalBeers
            }
            .onChange(of: store.totalBeers) { _, newValue in
                animateDisplayedTotal(to: newValue)
            }
            .onDisappear {
                totalAnimationTask?.cancel()
                toastDismissTask?.cancel()
            }
        }
    }

    private func addBeer(type: BeerType, amount: Int) {
        let entry = store.addEntry(type: type, amount: amount)
        let safeAmount = max(1, amount)
        undoableAction = UndoableAddAction(type: type, amount: safeAmount, entryIDs: [entry.id])

        Haptics.playAdd(for: type)

        let pour = PourPresentation(type: type, amount: amount)
        withAnimation(.easeInOut(duration: 0.2)) {
            activePour = pour
        }
        showToast("Added \(safeAmount) \(type == .tall ? "tall" : "normal")")

        scheduleToastDismiss(seconds: 4)
    }

    private func undoLastAdd() {
        guard let action = undoableAction else { return }

        guard action.amount <= max(0, store.totalBeers) else {
            undoableAction = nil
            showToast("Nothing to undo")
            scheduleToastDismiss(seconds: 1.6)
            return
        }

        let removed = store.removeEntries(withIDs: Set(action.entryIDs))
        undoableAction = nil

        let message: String
        if removed > 0 {
            message = "Undid \(action.amount) \(action.type == .tall ? "tall" : "normal")"
        } else {
            message = "Nothing to undo"
        }

        showToast(message)

        scheduleToastDismiss(seconds: 1.6)
    }

    private func showToast(_ message: String) {
        toastDismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            toastMessage = message
        }
    }

    private func scheduleToastDismiss(seconds: Double) {
        toastDismissTask?.cancel()
        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                toastMessage = nil
                undoableAction = nil
            }
        }
    }

    private func animateDisplayedTotal(to newTotal: Int) {
        totalAnimationTask?.cancel()

        let start = displayedTotal
        guard start != newTotal else { return }

        totalAnimationTask = Task { @MainActor in
            let duration = 0.5
            let frames = max(1, Int(duration / 0.016))
            let delta = newTotal - start

            for frame in 1...frames {
                if Task.isCancelled { return }

                let t = Double(frame) / Double(frames)
                let eased = 1 - pow(1 - t, 3)
                let value = Double(start) + Double(delta) * eased
                displayedTotal = Int(value.rounded())

                try? await Task.sleep(nanoseconds: 16_000_000)
            }

            displayedTotal = newTotal
        }
    }

    private static let startDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private struct UndoableAddAction {
    let type: BeerType
    let amount: Int
    let entryIDs: [UUID]
}

private struct AddBeerCard: View {
    let title: String
    let type: BeerType
    let tint: Color
    @Binding var amount: Int
    let buttonTitle: String
    let onAdd: () -> Void

    var body: some View {
        DashboardCard(title: title) {
            Stepper(value: $amount, in: 1...50) {
                Text("Amount: \(amount)")
                    .font(.subheadline.weight(.medium))
            }

            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(AppTheme.ink)
                .background(tint.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add \(amount) \(type == .tall ? "tall" : "normal") beers")
        }
    }
}

private struct PourPresentation: Equatable {
    let color: Color
    let label: String

    init(type: BeerType, amount: Int) {
        self.color = type == .tall ? AppTheme.tallAmber : AppTheme.normalGolden
        self.label = "\(amount)x \(type == .tall ? "Tall" : "Normal")"
    }
}

#Preview {
    HomeView()
        .environmentObject(BeerTrackerStore())
}
