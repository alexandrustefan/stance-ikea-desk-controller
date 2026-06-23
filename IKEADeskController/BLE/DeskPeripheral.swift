import CoreBluetooth
import Foundation

final class DeskPeripheral: NSObject {
    let peripheral: CBPeripheral

    private(set) var controlCharacteristic: CBCharacteristic?
    private(set) var positionCharacteristic: CBCharacteristic?
    private(set) var referenceInputCharacteristic: CBCharacteristic?

    var onGATTReady: (() -> Void)?

    var onPositionUpdate: ((DeskPosition) -> Void)?

    private var hasNotifiedGATTReady = false
    private var heightOffsetCM: Float

    init(peripheral: CBPeripheral, heightOffsetCM: Float) {
        self.peripheral = peripheral
        self.heightOffsetCM = heightOffsetCM
        super.init()
        peripheral.delegate = self
    }

    func updateOffset(_ offsetCM: Float) {
        heightOffsetCM = offsetCM
    }

    func discoverServices() {
        peripheral.discoverServices([
            CBUUID(string: AppConstants.LINAK.controlService),
            CBUUID(string: AppConstants.LINAK.positionService),
            CBUUID(string: AppConstants.LINAK.referenceInputService),
        ])
    }

    func writeCommand(_ data: Data) {
        guard let controlCharacteristic else { return }
        writeValue(data, for: controlCharacteristic)
    }

    func writeReferenceInput(_ data: Data) {
        guard let referenceInputCharacteristic else { return }
        writeValue(data, for: referenceInputCharacteristic)
    }

    private func writeValue(_ data: Data, for characteristic: CBCharacteristic) {
        let type: CBCharacteristicWriteType = characteristic.properties.contains(.writeWithoutResponse)
            ? .withoutResponse
            : .withResponse
        peripheral.writeValue(data, for: characteristic, type: type)
    }

    func readPosition() {
        guard let positionCharacteristic else { return }
        peripheral.readValue(for: positionCharacteristic)
    }
}

extension DeskPeripheral: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard peripheral.identifier == self.peripheral.identifier, let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard peripheral.identifier == self.peripheral.identifier,
              let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            switch characteristic.uuid.uuidString.uppercased() {
            case AppConstants.LINAK.controlCharacteristic.uppercased():
                controlCharacteristic = characteristic
            case AppConstants.LINAK.positionCharacteristic.uppercased():
                positionCharacteristic = characteristic
                peripheral.readValue(for: characteristic)
                peripheral.setNotifyValue(true, for: characteristic)
            case AppConstants.LINAK.referenceInputCharacteristic.uppercased():
                referenceInputCharacteristic = characteristic
            default:
                break
            }
        }
        validateGATTReady()
    }

    private func validateGATTReady() {
        guard !hasNotifiedGATTReady,
              controlCharacteristic != nil,
              positionCharacteristic != nil else { return }
        hasNotifiedGATTReady = true
        onGATTReady?()
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard characteristic.uuid.uuidString.uppercased() == AppConstants.LINAK.positionCharacteristic.uppercased(),
              let data = characteristic.value,
              let position = DeskProtocol.parsePositionData(data, offsetCM: heightOffsetCM)
        else { return }
        onPositionUpdate?(position)
    }
}
