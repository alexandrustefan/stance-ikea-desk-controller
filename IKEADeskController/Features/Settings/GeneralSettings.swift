import SwiftUI

struct GeneralSettings: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            settingsCard("Units") {
                Toggle("Use metric (cm)", isOn: $appState.useMetric)
            }
            settingsCard("Startup") {
                Toggle("Open at login", isOn: $appState.launchAtLogin)
            }
            settingsCard("Menu Bar") {
                Toggle("Show height in menu bar", isOn: $appState.showHeightInMenuBar)
                Text("Displays the current height next to the menu bar icon.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .glassCard(contentPadding: 16, cornerRadius: 14)
    }
}
