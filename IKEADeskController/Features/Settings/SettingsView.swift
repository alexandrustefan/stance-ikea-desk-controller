import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case desk
    case profiles
    case hotkeys
    case autoStand
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "General"
        case .desk: "Desk"
        case .profiles: "Profiles"
        case .hotkeys: "Hotkeys"
        case .autoStand: "Auto-Stand"
        case .about: "About"
        }
    }

    var icon: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .desk: "antenna.radiowaves.left.and.right"
        case .profiles: "person.2"
        case .hotkeys: "command"
        case .autoStand: "figure.stand"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @Bindable var appState: AppState
    @State private var selection: SettingsSection? = .general

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .frame(minWidth: 760, minHeight: 520)
    }

    private var sidebar: some View {
        List(selection: $selection) {
            Section {
                ForEach(SettingsSection.allCases) { section in
                    Label(section.title, systemImage: section.icon)
                        .tag(section)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                BrandHeader(compact: false)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                Divider()
            }
            .background(.bar)
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .general {
        case .general:
            SettingsDetailScaffold(title: "General", subtitle: "Units, startup, and menu bar") {
                GeneralSettings(appState: appState)
            }
        case .desk:
            SettingsDetailScaffold(title: "Desk", subtitle: "Register, switch, and connect multiple desks") {
                DeskConnectionSettings(appState: appState)
            }
        case .profiles:
            SettingsDetailScaffold(
                title: "Profiles",
                subtitle: "Sit, stand, and custom positions per workspace"
            ) {
                ProfilesSettings(appState: appState)
            }
        case .hotkeys:
            SettingsDetailScaffold(title: "Hotkeys", subtitle: "Global keyboard shortcuts for the active profile") {
                HotkeySettings(appState: appState)
            }
        case .autoStand:
            SettingsDetailScaffold(title: "Auto-Stand", subtitle: "Scheduled posture reminders") {
                AutoStandSettings(appState: appState)
            }
        case .about:
            SettingsDetailScaffold(title: "About", subtitle: "Version and credits") {
                AboutSettings()
            }
        }
    }
}

struct SettingsDetailScaffold<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.weight(.semibold))
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                content()
            }
            .frame(maxWidth: 640, alignment: .leading)
            .padding(28)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            if #available(macOS 26, *) {
                Color.clear
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        }
    }
}
