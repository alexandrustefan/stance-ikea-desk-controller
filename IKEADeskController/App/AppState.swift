import AppKit
import CoreBluetooth
import Foundation
import ServiceManagement

@MainActor
@Observable
final class AppState {
    static private(set) var current: AppState!

    let deskManager = DeskManager()
    let store = AppDataStore()
    let profileManager: ProfileManager
    let autoStandService = AutoStandService()
    let hotKeyService = HotKeyService()
    let notificationService = NotificationService()

    private(set) var deskDevices: [DeskDevice] = []
    var activeDesk: DeskDevice?
    var showCalibration = false
    var showDeskPicker = false
    var showSettings = false
    var autoStandCountdownText: String?

    var useMetric: Bool {
        didSet { store.useMetric = useMetric }
    }

    var launchAtLogin: Bool {
        didSet {
            store.launchAtLogin = launchAtLogin
            updateLaunchAtLogin(launchAtLogin)
        }
    }

    var showHeightInMenuBar: Bool {
        didSet { store.showHeightInMenuBar = showHeightInMenuBar }
    }

    var legacyMovementFallback: Bool {
        didSet {
            store.legacyMovementFallback = legacyMovementFallback
            deskManager.movement.useLegacyFallback = legacyMovementFallback
        }
    }

    var hasCompletedOnboarding: Bool {
        get { store.hasCompletedOnboarding }
        set { store.hasCompletedOnboarding = newValue }
    }

    init() {
        profileManager = ProfileManager(store: store)
        useMetric = store.useMetric
        launchAtLogin = store.launchAtLogin
        showHeightInMenuBar = store.showHeightInMenuBar
        legacyMovementFallback = store.legacyMovementFallback
        deskDevices = store.loadDeskDevices()
        activeDesk = deskDevices.first(where: { $0.id == store.loadActiveDeskID() }) ?? deskDevices.first
        deskManager.savedPeripheralUUID = store.savedPeripheralUUID ?? activeDesk?.peripheralUUID
        deskManager.movement.useLegacyFallback = store.legacyMovementFallback
        deskManager.movement.onArrived = { HapticService.playSuccess() }
        if let calibration = activeDesk?.calibration {
            deskManager.heightOffsetCM = calibration.heightOffset
        }

        deskManager.onDeskConnected = { [weak self] peripheral in
            Task { @MainActor in
                self?.handleDeskConnected(peripheral)
            }
        }

        if !store.hasCompletedOnboarding {
            showCalibration = true
        }

        deskManager.start()
        autoStandService.start(appState: self)
        notificationService.configure(appState: self)
        registerHotkeys()
        Task { await notificationService.requestAuthorization() }
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.deskManager.connectPreferredDesk()
            }
        }

        Self.current = self
        SpotlightIndexer.indexProfiles(profileManager.profiles)
        SpotlightIndexer.indexDesk(appState: self)
    }

    func handleDeskConnected(_ peripheral: CBPeripheral) {
        store.savedPeripheralUUID = peripheral.identifier
        deskManager.savedPeripheralUUID = peripheral.identifier

        if var existing = deskDevices.first(where: { $0.peripheralUUID == peripheral.identifier }) {
            existing.bleName = peripheral.name ?? existing.bleName
            existing.lastConnectedAt = .now
            let makeActive = activeDesk?.peripheralUUID == peripheral.identifier
            upsertDesk(existing, makeActive: makeActive)
            
            if profileManager.profiles(for: existing.id).isEmpty, store.hasCompletedOnboarding {
                _ = profileManager.createProfile(
                    name: deskDevices.count > 1 ? existing.title : "Work",
                    deskDeviceId: existing.id,
                    sitHeight: 72,
                    standHeight: 112
                )
            }
            return
        }

        let desk = DeskDevice(
            peripheralUUID: peripheral.identifier,
            bleName: peripheral.name ?? "My Desk"
        )
        upsertDesk(desk, makeActive: true)

        if profileManager.profiles(for: desk.id).isEmpty, store.hasCompletedOnboarding {
            _ = profileManager.createProfile(
                name: deskDevices.count > 1 ? desk.title : "Work",
                deskDeviceId: desk.id,
                sitHeight: 72,
                standHeight: 112
            )
        }
    }

    func upsertDesk(_ desk: DeskDevice, makeActive: Bool = true) {
        if let index = deskDevices.firstIndex(where: { $0.id == desk.id }) {
            deskDevices[index] = desk
        } else if let index = deskDevices.firstIndex(where: { $0.peripheralUUID == desk.peripheralUUID }) {
            var existing = deskDevices[index]
            existing.bleName = desk.bleName
            if !desk.displayName.isEmpty { existing.displayName = desk.displayName }
            existing.calibration = desk.calibration ?? existing.calibration
            existing.lastConnectedAt = desk.lastConnectedAt
            existing.isPaired = desk.isPaired
            deskDevices[index] = existing
        } else {
            deskDevices.append(desk)
        }
        store.saveDeskDevices(deskDevices)

        if makeActive {
            let resolved = deskDevices.first(where: { $0.id == desk.id })
                ?? deskDevices.first(where: { $0.peripheralUUID == desk.peripheralUUID })
                ?? desk
            setActiveDeskLocally(resolved)
        }
    }

    func updateDesk(_ desk: DeskDevice) {
        upsertDesk(desk, makeActive: activeDesk?.id == desk.id)
    }

    func switchActiveDesk(_ desk: DeskDevice) async {
        guard let resolved = deskDevices.first(where: { $0.id == desk.id }) else { return }
        guard activeDesk?.id != resolved.id else { return }

        setActiveDeskLocally(resolved)

        if profileManager.activeProfile?.deskDeviceId != resolved.id,
           let profile = profileManager.profiles(for: resolved.id).first {
            profileManager.setActiveProfile(profile)
            registerHotkeys()
        }

        await deskManager.reconnect()
    }

    private func setActiveDeskLocally(_ desk: DeskDevice) {
        activeDesk = deskDevices.first(where: { $0.id == desk.id }) ?? desk
        store.saveActiveDeskID(activeDesk?.id)
        deskManager.savedPeripheralUUID = activeDesk?.peripheralUUID
        store.savedPeripheralUUID = activeDesk?.peripheralUUID
        if let activeDesk {
            applyCalibration(for: activeDesk)
        }
    }

    private func applyCalibration(for desk: DeskDevice) {
        if let calibration = desk.calibration {
            deskManager.heightOffsetCM = calibration.heightOffset
            deskManager.deskPeripheral?.updateOffset(calibration.heightOffset)
        } else {
            deskManager.heightOffsetCM = DeskProtocol.defaultOffsetCM()
        }
    }

    func completeCalibration(
        calibration: DeskCalibration,
        sitHeight: Float,
        standHeight: Float,
        peripheralUUID: UUID,
        bleName: String
    ) {
        var desk = activeDesk ?? DeskDevice(peripheralUUID: peripheralUUID, bleName: bleName)
        desk.calibration = calibration
        desk.lastConnectedAt = .now
        desk.isPaired = true
        activeDesk = desk
        upsertDesk(desk)

        deskManager.heightOffsetCM = calibration.heightOffset
        deskManager.deskPeripheral?.updateOffset(calibration.heightOffset)

        if let existing = profileManager.profiles.first(where: { $0.deskDeviceId == desk.id }) {
            var profile = existing
            profile.sitHeight = sitHeight
            profile.standHeight = standHeight
            profileManager.updateProfile(profile)
            profileManager.setActiveProfile(profile)
        } else {
            _ = profileManager.createProfile(
                name: "Work",
                deskDeviceId: desk.id,
                sitHeight: sitHeight,
                standHeight: standHeight
            )
        }

        store.hasCompletedOnboarding = true
        showCalibration = false
    }

    func moveToSit() {
        guard let height = profileManager.activeProfile?.sitHeight else { return }
        Task { await moveToHeight(height) }
    }

    func moveToStand() {
        guard let height = profileManager.activeProfile?.standHeight else { return }
        Task { await moveToHeight(height) }
    }

    func moveToCustomPosition(_ position: CustomPosition) {
        Task { await moveToHeight(position.height) }
    }

    func moveToHeight(_ heightCM: Float) async {
        await deskManager.movement.moveToHeight(heightCM, offsetCM: deskManager.heightOffsetCM) { [weak self] in
            self?.deskManager.currentPosition
        }
    }

    func stopMovement() {
        deskManager.movement.stop()
    }

    func nudge(toward position: DeskPositionIntentValue) {
        switch position {
        case .sit:
            deskManager.movement.moveDown()
        case .stand:
            deskManager.movement.moveUp()
        }
    }

    func switchProfile(named name: String) -> Bool {
        guard let profile = profileManager.profiles.first(where: {
            $0.name.compare(name, options: .caseInsensitive) == .orderedSame
        }) else { return false }
        profileManager.setActiveProfile(profile)
        registerHotkeys()
        return true
    }

    var currentHeightCM: Double? {
        deskManager.currentPosition.map { Double($0.heightCM) }
    }

    var activeProfileName: String {
        profileManager.activeProfile?.name ?? "None"
    }

    var standingSessionSummary: String {
        let seconds = autoStandService.todayStandingDuration
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes)m standing today"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "\(hours)h \(remainingMinutes)m standing today"
    }

    func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .openSettingsWindow, object: nil)
    }

    func openCalibration() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .openCalibrationWindow, object: nil)
    }

    func disconnectDesk() {
        deskManager.disconnect(userInitiated: true)
    }

    func reconnectDesk() async {
        await deskManager.reconnect()
    }

    func scanForDesks() {
        deskManager.startManualScan()
    }

    func stopDeskScan() {
        deskManager.stopManualScan()
    }

    func connectToDiscoveredDesk(_ peripheral: CBPeripheral) {
        if let existing = deskDevices.first(where: { $0.peripheralUUID == peripheral.identifier }) {
            Task { await switchActiveDesk(existing) }
            return
        }

        let desk = DeskDevice(
            peripheralUUID: peripheral.identifier,
            bleName: peripheral.name ?? "Desk",
            displayName: peripheral.name ?? "Desk \(deskDevices.count + 1)"
        )
        upsertDesk(desk, makeActive: true)
        deskManager.connectToCandidate(peripheral)
        store.savedPeripheralUUID = peripheral.identifier
    }

    func forgetDesk() {
        guard let desk = activeDesk else { return }
        removeDesk(desk)
    }

    func removeDesk(_ desk: DeskDevice) {
        let wasActive = activeDesk?.id == desk.id
        deskDevices.removeAll { $0.id == desk.id }
        store.saveDeskDevices(deskDevices)

        guard wasActive else { return }

        deskManager.forgetAndDisconnect()

        if let next = deskDevices.first {
            Task { await switchActiveDesk(next) }
        } else {
            activeDesk = nil
            store.saveActiveDeskID(nil)
            store.savedPeripheralUUID = nil
        }
    }

    var connectedDeskPeripheralUUID: UUID? {
        guard deskManager.connectionState == .connected else { return nil }
        return deskManager.deskPeripheral?.peripheral.identifier
    }

    func openBluetoothSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Bluetooth-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    func updateHotkey(_ action: HotKeyService.HotkeyAction, combo: KeyCombo?) {
        guard var profile = profileManager.activeProfile else { return }
        if let combo,
           HotkeyConflictChecker.hasConflict(for: combo, in: profile.hotkeys, excluding: action) {
            return
        }
        switch action {
        case .moveSit: profile.hotkeys.moveSit = combo
        case .moveStand: profile.hotkeys.moveStand = combo
        case .moveUp: profile.hotkeys.moveUp = combo
        case .moveDown: profile.hotkeys.moveDown = combo
        case .cycleProfiles: profile.hotkeys.cycleProfiles = combo
        case .emergencyStop: profile.hotkeys.emergencyStop = combo
        }
        profileManager.updateProfile(profile)
        registerHotkeys()
    }

    var isInputMonitoringGranted: Bool {
        AccessibilityChecker.isInputMonitoringTrusted(prompt: false)
    }

    func requestInputMonitoringPermission() {
        _ = AccessibilityChecker.isInputMonitoringTrusted(prompt: true)
        registerHotkeys()
    }

    func openInputMonitoringSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
            NSWorkspace.shared.open(url)
        }
    }

    func registerHotkeys() {
        guard let profile = profileManager.activeProfile else { return }
        hotKeyService.register(bindings: profile.hotkeys, handlers: [
            .moveSit: { [weak self] in self?.moveToSit() },
            .moveStand: { [weak self] in self?.moveToStand() },
            .moveUp: { [weak self] in self?.deskManager.movement.beginHoldUp() },
            .moveDown: { [weak self] in self?.deskManager.movement.beginHoldDown() },
            .cycleProfiles: { [weak self] in
                guard let self, let deskId = activeDesk?.id else { return }
                profileManager.cycleActiveProfile(for: deskId)
                registerHotkeys()
            },
            .emergencyStop: { [weak self] in self?.stopMovement() },
        ], onKeyUp: { [weak self] action in
            switch action {
            case .moveUp, .moveDown:
                self?.deskManager.movement.endHold()
            default:
                break
            }
        })
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Registration can fail in unsigned debug builds.
        }
    }
}
