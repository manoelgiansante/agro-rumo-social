import SwiftUI

struct ContentView: View {
    @State private var viewModel = DashboardViewModel()
    @State private var selectedTab: AppTab = .dashboard
    @State private var showCreatePost = false

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Dashboard", systemImage: "square.grid.2x2.fill", value: .dashboard) {
                NavigationStack {
                    DashboardView(viewModel: viewModel)
                }
            }

            Tab("Calendário", systemImage: "calendar", value: .calendar) {
                NavigationStack {
                    CalendarView(viewModel: viewModel)
                }
            }

            Tab("Criar", systemImage: "plus.circle.fill", value: .create) {
                Color.clear
            }

            Tab("Métricas", systemImage: "chart.bar.fill", value: .metrics) {
                NavigationStack {
                    MetricsView(viewModel: viewModel)
                }
            }

            Tab("Config", systemImage: "gearshape.fill", value: .settings) {
                NavigationStack {
                    SettingsView(viewModel: viewModel)
                }
            }
        }
        .tint(.green)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .create {
                showCreatePost = true
                selectedTab = .dashboard
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadData()
        }
    }
}

enum AppTab: Hashable {
    case dashboard
    case calendar
    case create
    case metrics
    case settings
}
