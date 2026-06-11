import SwiftUI

struct MenuBarPopover: View {
    @Bindable var appState: AppState
    @Environment(\.openWindow) private var openWindow

    private var isConnected: Bool {
        appState.deskManager.connectionState == .connected
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            BrandHeader(compact: true, subtitle: deskSubtitle)

            PositionDisplay(
                heightText: heightText,
                percentText: percentText,
                useGlass: false
            )

            if appState.deskDevices.count > 1 {
                QuickDeskPicker(
                    desks: appState.deskDevices,
                    activeDesk: appState.activeDesk,
                    connectedPeripheralUUID: appState.connectedDeskPeripheralUUID,
                    onSelect: { desk in
                        Task { await appState.switchActiveDesk(desk) }
                    }
                )
            }

            QuickProfilePicker(
                profiles: profilesForActiveDesk,
                activeProfile: appState.profileManager.activeProfile,
                onSelect: {
                    appState.profileManager.setActiveProfile($0)
                    appState.registerHotkeys()
                }
            )

            DeskControls(
                isConnected: isConnected,
                onBeginUp: { appState.deskManager.movement.beginHoldUp() },
                onBeginDown: { appState.deskManager.movement.beginHoldDown() },
                onEndHold: { appState.deskManager.movement.endHold() },
                onStop: { appState.stopMovement() }
            )

            positionButtons

            if let countdown = appState.autoStandCountdownText {
                Label(countdown, systemImage: "timer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !isConnected {
                Text("Connect your desk in Settings → Desk to move.")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            footer
        }
        .padding(16)
        .frame(width: 300)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .task {
            if appState.showCalibration {
                openWindow(id: "calibration")
            }
            if appState.deskManager.discoveredCandidates.count > 1,
               appState.deskManager.connectionState == .scanning {
                openWindow(id: "desk-picker")
            }
        }
    }

    private var profilesForActiveDesk: [DeskProfile] {
        guard let deskId = appState.activeDesk?.id else {
            return appState.profileManager.profiles
        }
        let filtered = appState.profileManager.profiles(for: deskId)
        return filtered.isEmpty ? appState.profileManager.profiles : filtered
    }

    private var deskSubtitle: String? {
        let name = appState.activeDesk?.title ?? "My Desk"
        return "\(connectionStatusText) · \(name)"
    }

    private var connectionStatusText: String {
        switch appState.deskManager.connectionState {
        case .connected: "Connected"
        case .connecting: "Connecting"
        case .scanning: "Scanning"
        case .disconnected: "Disconnected"
        }
    }

    private var heightText: String {
        guard let height = appState.deskManager.currentPosition?.heightCM else {
            return "—"
        }
        return UnitConverter.formatHeight(height, useMetric: appState.useMetric)
    }

    private var percentText: String? {
        guard let height = appState.deskManager.currentPosition?.heightCM,
              let calibration = appState.activeDesk?.calibration
        else { return nil }
        let percent = calibration.percentInRange(heightCM: height)
        return String(format: "%.0f%% of range", percent)
    }

    @ViewBuilder
    private var positionButtons: some View {
        let profile = appState.profileManager.activeProfile

        VStack(alignment: .leading, spacing: 8) {
            Text("Positions")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                PrimaryPositionButton(title: "Sit", systemImage: "chair.fill", heightCM: profile?.sitHeight) {
                    appState.moveToSit()
                }
                PrimaryPositionButton(title: "Stand", systemImage: "figure.stand", heightCM: profile?.standHeight) {
                    appState.moveToStand()
                }
            }
            .disabled(!isConnected)

            if let custom = profile?.customPositions, !custom.isEmpty {
                Text("Custom")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)

                FlowLayout(spacing: 6) {
                    ForEach(custom) { position in
                        CustomPositionChip(position: position, useMetric: appState.useMetric) {
                            appState.moveToCustomPosition(position)
                        }
                        .disabled(!isConnected)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 0) {
            Button("Settings") { appState.openSettings() }
            Spacer()
            Button("Recalibrate") { appState.openCalibration() }
            Spacer()
            Button("Quit") { appState.quitApp() }
                .foregroundStyle(.secondary)
        }
        .font(.caption)
        .buttonStyle(.plain)
        .padding(.top, 2)
    }
}

// MARK: - Position controls (no Liquid Glass — reliable clicks in NSPopover)

private struct PrimaryPositionButton: View {
    let title: String
    let systemImage: String
    let heightCM: Float?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let heightCM {
                    Text("\(Int(heightCM)) cm")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PopoverPrimaryButtonStyle())
    }
}

private struct CustomPositionChip: View {
    let position: CustomPosition
    let useMetric: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: position.icon)
                    .font(.caption.weight(.semibold))
                Text(position.name)
                    .font(.caption.weight(.medium))
                Text(UnitConverter.formatHeight(position.height, useMetric: useMetric))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Capsule())
        }
        .buttonStyle(PopoverChipButtonStyle())
    }
}

private struct PopoverPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(BrandTheme.accent)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(configuration.isPressed ? BrandTheme.accentSoft : BrandTheme.accentMuted)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(BrandTheme.accent.opacity(0.22), lineWidth: 1)
            }
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

private struct PopoverChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background {
                Capsule()
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.08 : 0.04))
            }
            .overlay {
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            }
    }
}

/// Simple left-to-right wrapping layout for custom position chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            if current.indices.isEmpty {
                current.width = size.width
            } else {
                current.width += spacing + size.width
            }
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
