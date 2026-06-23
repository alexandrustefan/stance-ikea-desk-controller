import CoreBluetooth
import SwiftUI

struct DeskConnectionSettings: View {
    @Bindable var appState: AppState

    private var deskManager: DeskManager { appState.deskManager }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            connectionHUDRow
            
            registeredDesksCard
            
            if deskManager.isManualScanning || !deskManager.discoveredCandidates.isEmpty {
                nearbyDesksCard
            }
            
            advancedSettingsCard
        }
    }

    // MARK: - Components

    private var connectionHUDRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                // Connection badge + description
                VStack(alignment: .leading, spacing: 6) {
                    Text("Connection Status")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(connectionColor)
                            .frame(width: 8, height: 8)
                            .shadow(color: connectionColor.opacity(0.5), radius: 3)
                        
                        Text(connectionLabel)
                            .font(.headline.weight(.semibold))
                    }
                    
                    if let activeDesk = appState.activeDesk {
                        Text(activeDesk.title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No desk configured")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Height display
                if let height = appState.currentHeightCM {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Current Height")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(UnitConverter.formatHeight(Float(height), useMetric: appState.useMetric))
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(BrandTheme.accent)
                    }
                }
            }
            
            Divider()
            
            // Bluetooth Status and Actions
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: bluetoothStateIcon)
                        .foregroundStyle(bluetoothStateColor)
                    Text("Bluetooth \(bluetoothStateLabel)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if deskManager.connectionState == .connected || deskManager.connectionState == .connecting {
                        Button("Disconnect") { appState.disconnectDesk() }
                            .adaptiveControlButtonStyle()
                    } else {
                        Button("Connect") {
                            Task { await appState.reconnectDesk() }
                        }
                        .disabled(deskManager.bluetoothState != .poweredOn || appState.activeDesk == nil)
                        .adaptiveControlButtonStyle(prominent: true)
                    }

                    if deskManager.isManualScanning {
                        Button("Stop Scanning") { appState.stopDeskScan() }
                            .adaptiveControlButtonStyle()
                    } else {
                        Button("Add Desk…") { appState.scanForDesks() }
                            .disabled(deskManager.bluetoothState != .poweredOn)
                            .adaptiveControlButtonStyle(prominent: false)
                    }
                }
            }
            
            if deskManager.userPausedAutoReconnect, deskManager.connectionState == .disconnected {
                Text("Auto-reconnect is paused until you connect or scan again.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .glassCard(contentPadding: 16, cornerRadius: 16)
    }

    private var registeredDesksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Registered Desks")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 0) {
                if appState.deskDevices.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "table.furniture")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                        Text("No desks registered yet. Click Add Desk to pair your first one.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 16)
                } else {
                    ForEach(appState.deskDevices) { desk in
                        registeredDeskRow(desk)
                        if desk.id != appState.deskDevices.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
            .glassCard(contentPadding: 0, cornerRadius: 16)
        }
    }

    private var nearbyDesksCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Nearby Desks")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if deskManager.isManualScanning {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.7)
                        Text("Scanning…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            VStack(spacing: 0) {
                if deskManager.discoveredCandidates.isEmpty {
                    HStack(spacing: 12) {
                        Spacer()
                        Text("Searching for Linak/Idåsen desks. Ensure your desk is in pairing mode (LED blinking blue).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                } else {
                    ForEach(deskManager.discoveredCandidates, id: \.identifier) { peripheral in
                        nearbyDeskRow(peripheral)
                        if peripheral.identifier != deskManager.discoveredCandidates.last?.identifier {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
            }
            .glassCard(contentPadding: 0, cornerRadius: 16)
        }
    }

    private var advancedSettingsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Advanced Settings")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Use legacy up/down movement fallback", isOn: $appState.legacyMovementFallback)
                    .toggleStyle(.switch)
                
                Text("Enable this only if the desk stalls or reference height commands fail on your LINAK controller.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                HStack(spacing: 12) {
                    Button("Open Bluetooth Settings") {
                        appState.openBluetoothSettings()
                    }
                    .adaptiveControlButtonStyle()
                    
                    if appState.activeDesk?.calibration == nil {
                        Button("Run calibration…") {
                            appState.openCalibration()
                        }
                        .adaptiveControlButtonStyle(prominent: true)
                    } else {
                        Button("Recalibrate…") {
                            appState.openCalibration()
                        }
                        .adaptiveControlButtonStyle()
                    }
                }
            }
            .glassCard(contentPadding: 16, cornerRadius: 16)
        }
    }

    // MARK: - Rows

    private func registeredDeskRow(_ desk: DeskDevice) -> some View {
        let isActive = appState.activeDesk?.id == desk.id
        let isConnected = appState.connectedDeskPeripheralUUID == desk.peripheralUUID
        
        return HStack(alignment: .center, spacing: 14) {
            // Desk Icon Status
            ZStack {
                Circle()
                    .fill(isActive ? BrandTheme.accentSoft : Color.primary.opacity(0.04))
                    .frame(width: 36, height: 36)
                
                Image(systemName: isConnected ? "table.furniture.fill" : "table.furniture")
                    .font(.system(size: 16))
                    .foregroundStyle(isActive ? BrandTheme.accent : .secondary)
            }
            .padding(.leading, 14)
            
            // Textfields and status details
            VStack(alignment: .leading, spacing: 2) {
                TextField("Desk Name", text: displayNameBinding(for: desk))
                    .font(.body.weight(.semibold))
                    .textFieldStyle(.plain)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 6) {
                    Text(desk.bleName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if isActive {
                        Text("Active")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(BrandTheme.accent)
                    } else {
                        Button("Switch to desk") {
                            Task { await appState.switchActiveDesk(desk) }
                        }
                        .buttonStyle(.plain)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.tint)
                    }
                    
                    if isConnected {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                    
                    if desk.calibration != nil {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Label("Calibrated", systemImage: "ruler.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Actions
            Button(role: .destructive) {
                appState.removeDesk(desk)
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
            .help("Forget desk")
        }
        .padding(.vertical, 12)
    }

    private func nearbyDeskRow(_ peripheral: CBPeripheral) -> some View {
        let isRegistered = appState.deskDevices.contains { $0.peripheralUUID == peripheral.identifier }
        let rssi = deskManager.rssi(for: peripheral)
        
        return HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.04))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 14)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(peripheral.name ?? "Unknown Desk")
                    .font(.body.weight(.semibold))
                
                if let rssi {
                    HStack(spacing: 4) {
                        Image(systemName: rssiIcon(for: rssi))
                            .font(.caption2)
                        Text("Signal: \(rssi) dBm")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button {
                appState.connectToDiscoveredDesk(peripheral)
            } label: {
                Text(isRegistered ? "Switch" : "Pair & Add")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(BrandTheme.accentSoft, in: Capsule())
                    .foregroundStyle(BrandTheme.accent)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 14)
        }
        .padding(.vertical, 12)
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

    private func rssiIcon(for rssi: Int) -> String {
        if rssi > -60 {
            return "cellularbars"
        } else if rssi > -80 {
            return "cellularbars"
        } else {
            return "cellularbars"
        }
    }

    // MARK: - Helper state logic

    private var connectionColor: Color {
        switch deskManager.connectionState {
        case .connected: BrandTheme.accent
        case .connecting, .scanning: .orange
        case .disconnected: .red
        }
    }
    
    private var connectionLabel: String {
        switch deskManager.connectionState {
        case .connected: "Connected"
        case .connecting: "Connecting…"
        case .scanning: "Scanning…"
        case .disconnected: "Disconnected"
        }
    }

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

