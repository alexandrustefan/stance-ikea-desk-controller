import SwiftUI

struct GeneralSettings: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsCard("Units") {
                Toggle("Use metric (cm)", isOn: $appState.useMetric)
                    .toggleStyle(.switch)
                    .font(.body.weight(.semibold))
            }
            settingsCard("Startup") {
                Toggle("Open at login", isOn: $appState.launchAtLogin)
                    .toggleStyle(.switch)
                    .font(.body.weight(.semibold))
            }
            settingsCard("Menu Bar") {
                Toggle("Show height in menu bar", isOn: $appState.showHeightInMenuBar)
                    .toggleStyle(.switch)
                    .font(.body.weight(.semibold))
                Text("Displays the current height next to the menu bar icon.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .glassCard(contentPadding: 16, cornerRadius: 16)
    }
}

