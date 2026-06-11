import CoreBluetooth
import SwiftUI

struct DeskConnectionSettings: View {
    @Bindable var appState: AppState

    private var deskManager: DeskManager { appState.deskManager }

    var body: some View {
        Form {
            connectionSection
            registeredDesksSection
            if deskManager.isManualScanning || !deskManager.discoveredCandidates.isEmpty {
                nearbyDesksSection
            }
            advancedSection
        }
        .formStyle(.grouped)
    }

    // MARK: - Sections

    private var connectionSection: some View {
        Section {
            ConnectionBadge(
                state: deskManager.connectionState,
                deskName: appState.activeDesk?.title ?? "No desk selected"
            )

            LabeledContent("Bluetooth") {
                Label(bluetoothStateLabel, systemImage: bluetoothStateIcon)
                    .font(.caption)
                    .foregroundStyle(bluetoothStateColor)
            }

            if let height = appState.currentHeightCM {
                LabeledContent("Height") {
                    Text(UnitConverter.formatHeight(Float(height), useMetric: appState.useMetric))
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                if deskManager.connectionState == .connected || deskManager.connectionState == .connecting {
                    Button("Disconnect") { appState.disconnectDesk() }
                } else {
                    Button("Connect") {
                        Task { await appState.reconnectDesk() }
                    }
                    .disabled(deskManager.bluetoothState != .poweredOn || appState.activeDesk == nil)
                }

                if deskManager.isManualScanning {
                    Button("Stop Scanning") { appState.stopDeskScan() }
                } else {
                    Button("Add Desk…") { appState.scanForDesks() }
                        .disabled(deskManager.bluetoothState != .poweredOn)
                }
            }
            .buttonStyle(.bordered)

            if deskManager.userPausedAutoReconnect, deskManager.connectionState == .disconnected {
                Text("Auto-reconnect is paused until you connect or scan again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Connection")
        } footer: {
            Text("Wake the desk keypad, then use Add Desk to register another LINAK / IDÅSEN desk.")
        }
    }

    private var registeredDesksSection: some View {
        Section {
            if appState.deskDevices.isEmpty {
                Text("No desks registered yet. Tap Add Desk to pair your first one.")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Active desk", selection: activeDeskIDBinding) {
                    ForEach(appState.deskDevices) { desk in
                        Text(desk.title).tag(desk.id)
                    }
                }

                ForEach(appState.deskDevices) { desk in
                    registeredDeskRow(desk)
                }
            }
        } header: {
            Text("Registered desks")
        } footer: {
            Text("Each desk keeps its own calibration. Profiles are linked to a specific desk.")
        }
    }

    private var nearbyDesksSection: some View {
        Section("Nearby desks") {
            if deskManager.discoveredCandidates.isEmpty {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Scanning…")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(deskManager.discoveredCandidates, id: \.identifier) { peripheral in
                    nearbyDeskRow(peripheral)
                }
            }
        }
    }

    private var advancedSection: some View {
        Section("Advanced") {
            Toggle("Use legacy up/down movement fallback", isOn: $appState.legacyMovementFallback)

            Button("Open Bluetooth Settings") {
                appState.openBluetoothSettings()
            }

            if appState.activeDesk?.calibration == nil {
                Button("Run calibration…") {
                    appState.openCalibration()
                }
            }
        }
    }

    // MARK: - Rows

    private func registeredDeskRow(_ desk: DeskDevice) -> some View {
        let isActive = appState.activeDesk?.id == desk.id
        let isConnected = appState.connectedDeskPeripheralUUID == desk.peripheralUUID

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Name", text: displayNameBinding(for: desk))
                        .textFieldStyle(.roundedBorder)

                    Text(desk.bleName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        if isActive {
                            Text("ACTIVE")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(BrandTheme.accent)
                        }
                        if isConnected {
                            Label("Connected", systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        } else if isActive {
                            Label("Not connected", systemImage: "circle")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        if desk.calibration != nil {
                            Label("Calibrated", systemImage: "ruler")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                Button(role: .destructive) {
                    appState.removeDesk(desk)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Remove desk")
            }

            if !isActive {
                Button("Switch to this desk") {
                    Task { await appState.switchActiveDesk(desk) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }

    private func nearbyDeskRow(_ peripheral: CBPeripheral) -> some View {
        let isRegistered = appState.deskDevices.contains { $0.peripheralUUID == peripheral.identifier }
        let rssi = deskManager.rssi(for: peripheral)

        return Button {
            appState.connectToDiscoveredDesk(peripheral)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(peripheral.name ?? "Unknown Desk")
                        .font(.subheadline.weight(.medium))
                    if let rssi {
                        Text("Signal \(rssi) dBm")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text(isRegistered ? "Switch" : "Add")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.accent)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bindings

    private var activeDeskIDBinding: Binding<UUID> {
        Binding(
            get: { appState.activeDesk?.id ?? appState.deskDevices[0].id },
            set: { id in
                guard let desk = appState.deskDevices.first(where: { $0.id == id }) else { return }
                Task { await appState.switchActiveDesk(desk) }
            }
        )
    }

    private func displayNameBinding(for desk: DeskDevice) -> Binding<String> {
        Binding(
            get: {
                appState.deskDevices.first(where: { $0.id == desk.id })?.displayName ?? desk.displayName
            },
            set: { newName in
                guard var updated = appState.deskDevices.first(where: { $0.id == desk.id }) else { return }
                updated.displayName = newName
                appState.updateDesk(updated)
            }
        )
    }

    // MARK: - Bluetooth status

    private var bluetoothStateLabel: String {
        switch deskManager.bluetoothState {
        case .poweredOn: "On"
        case .poweredOff: "Off"
        case .unauthorized: "Permission denied"
        case .unsupported: "Unavailable"
        case .resetting: "Resetting"
        default: "Unknown"
        }
    }

    private var bluetoothStateIcon: String {
        switch deskManager.bluetoothState {
        case .poweredOn: "checkmark.circle.fill"
        case .poweredOff: "bolt.slash.fill"
        case .unauthorized: "exclamationmark.triangle.fill"
        default: "questionmark.circle"
        }
    }

    private var bluetoothStateColor: Color {
        switch deskManager.bluetoothState {
        case .poweredOn: BrandTheme.accent
        case .poweredOff, .unauthorized: .orange
        default: .secondary
        }
    }
}
