import SwiftUI

struct InfoView: View {
    @EnvironmentObject private var store: BeerTrackerStore
    @State private var showResetConfirmation = false
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    VStack(spacing: 14) {
                        DashboardCard(title: "Summary", subtitle: "Since \(Self.startDateFormatter.string(from: store.startDate))") {
                            StatLine(title: "Total", value: "\(store.totalBeers)")
                            StatLine(title: "Tall", value: "\(store.totalTallBeers)")
                            StatLine(title: "Normal", value: "\(store.totalNormalBeers)")
                            StatLine(title: "Days", value: "\(store.trackedDaysCount)")
                            StatLine(
                                title: "Per day (avg)",
                                value: store.trackedDaysCount == 0
                                    ? "0.0"
                                    : String(format: "%.1f", store.averageBeersPerTrackedDay)
                            )
                        }

                        DashboardCard(title: "Today") {
                            HStack(spacing: 10) {
                                CompactStatPill(title: "Tall", value: "\(store.todaysTallBeers)", tint: AppTheme.tallAmber)
                                CompactStatPill(title: "Normal", value: "\(store.todaysNormalBeers)", tint: AppTheme.normalGolden)
                                CompactStatPill(title: "Total", value: "\(store.todaysTotalBeers)", tint: AppTheme.outline)
                            }
                        }

                        DashboardCard(title: "Tracking") {
                            Text("Start Date")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            DatePicker(
                                "Start Date",
                                selection: $store.startDate,
                                displayedComponents: .date
                            )
                            .labelsHidden()

                            Button(role: .destructive) {
                                showResetConfirmation = true
                            } label: {
                                Text("Reset Start Date and Clear Entries")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("About") {
                        showAbout = true
                    }
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .alert("Reset Tracking?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetTracking()
                }
            } message: {
                Text("This will set Start Date to today and remove all entries.")
            }
        }
    }

    private static let startDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private struct AboutView: View {
    private let supportURL = URL(string: "https://example.com/support")!
    private let privacyURL = URL(string: "https://example.com/privacy")!
    private let emailURL = URL(string: "mailto:support@example.com")!

    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()

                ScrollView {
                    VStack(spacing: 14) {
                        DashboardCard(title: "Beer Counter", subtitle: versionText) {
                            Text("A simple way to track your beer count over time.")
                                .font(.body)
                                .foregroundStyle(AppTheme.ink.opacity(0.85))
                        }

                        DashboardCard(title: "Help & Privacy") {
                            Link("Support", destination: supportURL)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.tallAmber)

                            Link("Email Support", destination: emailURL)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.tallAmber)

                            Link("Privacy Policy", destination: privacyURL)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(AppTheme.tallAmber)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("About")
        }
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}

private struct StatLine: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(AppTheme.ink.opacity(0.8))
            Spacer()
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(AppTheme.ink)
        }
        .padding(.vertical, 2)
    }
}

private struct CompactStatPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.ink.opacity(0.75))
            Text(value)
                .font(.title3.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    InfoView()
        .environmentObject(BeerTrackerStore())
}
