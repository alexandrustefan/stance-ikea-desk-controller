import CoreBluetooth
import Foundation

@MainActor
@Observable
final class DeskManager: NSObject {
    private(set) var connectionState: DeskConnectionState = .disconnected
    private(set) var currentPosition: DeskPosition?
    private(set) var deskPeripheral: DeskPeripheral?
    private(set) var discoveredCandidates: [CBPeripheral] = []
    private(set) var bluetoothState: CBManagerState = .unknown
    private(set) var isManualScanning = false
    private(set) var userPausedAutoReconnect = false
    private(set) var connectionErrorMessage: String?

    let movement = DeskMovementController()

    var heightOffsetCM: Float = DeskProtocol.defaultOffsetCM()
    var savedPeripheralUUID: UUID?
    var onDeskConnected: ((CBPeripheral) -> Void)?

    private nonisolated(unsafe) var centralManager: CBCentralManager!
    private let bleQueue = DispatchQueue(label: "com.alexandrustefan.ikea-desk-controller.ble")
    private nonisolated(unsafe) var peripheralRegistry: [UUID: CBPeripheral] = [:]
    private var reconnectAttempt = 0
    private var reconnectTask: Task<Void, Never>?
    private var candidateRSSI: [UUID: Int] = [:]
    private var manualScanFallbackTask: Task<Void, Never>?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: bleQueue)
    }

    func start() {
        Task { await connectPreferredDesk() }
    }

    func connectPreferredDesk() async {
        guard !userPausedAutoReconnect else { return }
        let savedID = savedPeripheralUUID
        await runOnBLEQueue { [self] in
            guard centralManager.state == .poweredOn else { return }

            if let savedID,
               let retrieved = centralManager.retrievePeripherals(withIdentifiers: [savedID]).first {
                peripheralRegistry[retrieved.identifier] = retrieved
                Task { @MainActor in
                    connect(to: retrieved)
                }
                return
            }

            Task { @MainActor in
                beginScanningOnBLEQueue()
            }
        }
    }

    private func beginScanningOnBLEQueue() {
        connectionState = deskPeripheral == nil ? .scanning : connectionState
        if !isManualScanning {
            discoveredCandidates = []
            candidateRSSI = [:]
        }
        bleQueue.async { [self] in
            centralManager.scanForPeripherals(
                withServices: [CBUUID(string: AppConstants.LINAK.controlService)],
                options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
            )
        }

        guard !isManualScanning else { return }

        manualScanFallbackTask?.cancel()
        manualScanFallbackTask = Task {
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled, !isManualScanning, connectionState == .scanning else { return }
            bleQueue.async { [self] in
                centralManager.stopScan()
                centralManager.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }

    func startManualScan() {
        userPausedAutoReconnect = false
        isManualScanning = true
        reconnectTask?.cancel()
        manualScanFallbackTask?.cancel()
        discoveredCandidates = []
        candidateRSSI = [:]
        if deskPeripheral == nil {
            connectionState = .scanning
        }
        beginScanningOnBLEQueue()

        manualScanFallbackTask = Task {
            try? await Task.sleep(for: .seconds(12))
            guard !Task.isCancelled, isManualScanning else { return }
            bleQueue.async { [self] in
                centralManager.stopScan()
                centralManager.scanForPeripherals(withServices: nil, options: nil)
            }
        }
    }

    func stopManualScan() {
        isManualScanning = false
        manualScanFallbackTask?.cancel()
        bleQueue.async { [self] in
            centralManager.stopScan()
        }
        if deskPeripheral != nil {
            connectionState = .connected
        } else if connectionState == .scanning {
            connectionState = .disconnected
        }
    }

    func rssi(for peripheral: CBPeripheral) -> Int? {
        candidateRSSI[peripheral.identifier]
    }

    func connect(to peripheral: CBPeripheral) {
        userPausedAutoReconnect = false
        isManualScanning = false
        manualScanFallbackTask?.cancel()
        peripheralRegistry[peripheral.identifier] = peripheral
        connectionState = .connecting
        let id = peripheral.identifier
        bleQueue.async { [self] in
            centralManager.stopScan()
            guard let peripheral = peripheralRegistry[id] else { return }
            centralManager.connect(peripheral, options: nil)
        }
    }

    func connectToCandidate(_ peripheral: CBPeripheral) {
        savedPeripheralUUID = peripheral.identifier
        connect(to: peripheral)
    }

    func disconnect(userInitiated: Bool = false) {
        if userInitiated {
            userPausedAutoReconnect = true
            isManualScanning = false
        }
        reconnectTask?.cancel()
        manualScanFallbackTask?.cancel()
        bleQueue.async { [self] in
            centralManager.stopScan()
        }
        if let peripheral = deskPeripheral?.peripheral {
            let id = peripheral.identifier
            bleQueue.async { [self] in
                guard let peripheral = peripheralRegistry[id] else { return }
                centralManager.cancelPeripheralConnection(peripheral)
            }
        }
        teardownConnection()
    }

    func forgetAndDisconnect() {
        savedPeripheralUUID = nil
        userPausedAutoReconnect = true
        isManualScanning = false
        disconnect()
    }

    func reconnect() async {
        userPausedAutoReconnect = false
        reconnectAttempt = 0
        await connectPreferredDesk()
    }

    private func teardownConnection() {
        movement.detach()
        deskPeripheral = nil
        currentPosition = nil
        connectionState = .disconnected
    }

    private func setupDeskPeripheral(_ peripheral: CBPeripheral) {
        let desk = DeskPeripheral(peripheral: peripheral, heightOffsetCM: heightOffsetCM)
        desk.onPositionUpdate = { [weak self] position in
            Task { @MainActor in
                self?.currentPosition = position
                if let appState = AppState.current {
                    SpotlightIndexer.indexDesk(appState: appState)
                }
            }
        }
        desk.onGATTReady = { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.connectionState = .connected
                self.connectionErrorMessage = nil
                self.reconnectAttempt = 0
                self.onDeskConnected?(peripheral)
            }
        }
        deskPeripheral = desk
        movement.attach(desk)
        connectionState = .connecting
        bleQueue.async {
            desk.discoverServices()
        }
    }

    private func scheduleReconnect() {
        guard !userPausedAutoReconnect else { return }
        reconnectTask?.cancel()
        reconnectTask = Task {
            let delay = min(pow(2.0, Double(reconnectAttempt)), 30)
            reconnectAttempt += 1
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await connectPreferredDesk()
        }
    }

    private func peripheral(for id: UUID) -> CBPeripheral? {
        peripheralRegistry[id]
    }

    private func handleDiscovered(peripheralID: UUID, rssi: Int, isValid: Bool) {
        guard isValid, let peripheral = peripheral(for: peripheralID) else { return }

        if !discoveredCandidates.contains(where: { $0.identifier == peripheralID }) {
            discoveredCandidates.append(peripheral)
        }
        candidateRSSI[peripheralID] = rssi

        if isManualScanning { return }

        if connectionState == .scanning || connectionState == .disconnected {
            if discoveredCandidates.count == 1 {
                connect(to: peripheral)
            } else if let best = bestCandidate(), best.identifier == peripheralID, savedPeripheralUUID == nil {
                connect(to: best)
            }
        }
    }

    private func handleConnected(peripheralID: UUID) {
        guard let peripheral = peripheral(for: peripheralID) else { return }
        savedPeripheralUUID = peripheralID
        setupDeskPeripheral(peripheral)
    }

    private func bestCandidate() -> CBPeripheral? {
        if let savedPeripheralUUID,
           let saved = discoveredCandidates.first(where: { $0.identifier == savedPeripheralUUID }) {
            return saved
        }
        return discoveredCandidates.max { lhs, rhs in
            (candidateRSSI[lhs.identifier] ?? Int.min) < (candidateRSSI[rhs.identifier] ?? Int.min)
        }
    }

    private func runOnBLEQueue(_ work: @escaping @Sendable () -> Void) async {
        await withCheckedContinuation { continuation in
            bleQueue.async {
                work()
                continuation.resume()
            }
        }
    }

    private nonisolated static func isValidCandidate(
        name: String?,
        advertisement: [String: Any]
    ) -> Bool {
        if let serviceUUIDs = advertisement[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID],
           serviceUUIDs.contains(where: { $0.uuidString.uppercased() == AppConstants.LINAK.controlService.uppercased() }) {
            return true
        }
        return DeskProtocol.matchesDeskName(name)
    }

    private nonisolated static func connectionErrorMessage(for error: Error?) -> String {
        if let cbError = error as? CBError {
            switch cbError.code {
            case .connectionTimeout:
                return "Connection timed out. Move closer to your desk and try again."
            case .peerRemovedPairingInformation:
                return "Pairing information changed. Remove the desk in Settings and pair again."
            case .peripheralDisconnected:
                return "Desk disconnected. Another device may be connected — close the IKEA or LINAK app on your phone."
            default:
                break
            }
        }
        return "Could not connect. Disconnect other apps from your desk (IKEA Home smart, LINAK) and try again."
    }
}

extension DeskManager: CBCentralManagerDelegate {
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        let isPoweredOn = state == .poweredOn
        Task { @MainActor in
            bluetoothState = state
            if isPoweredOn {
                await connectPreferredDesk()
            } else {
                teardownConnection()
            }
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let peripheralID = peripheral.identifier
        peripheralRegistry[peripheralID] = peripheral
        let rssiValue = RSSI.intValue
        let isValid = Self.isValidCandidate(name: peripheral.name, advertisement: advertisementData)
        Task { @MainActor in
            handleDiscovered(peripheralID: peripheralID, rssi: rssiValue, isValid: isValid)
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        let peripheralID = peripheral.identifier
        peripheralRegistry[peripheralID] = peripheral
        central.stopScan()
        Task { @MainActor in
            handleConnected(peripheralID: peripheralID)
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        let message = Self.connectionErrorMessage(for: error)
        Task { @MainActor in
            connectionErrorMessage = message
            connectionState = .disconnected
            teardownConnection()
            scheduleReconnect()
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            teardownConnection()
            scheduleReconnect()
        }
    }
}
