import Foundation

@MainActor
final class DeskMovementController {
    private weak var deskPeripheral: DeskPeripheral?
    private var moveTask: Task<Void, Never>?
    private var holdTask: Task<Void, Never>?
    private(set) var isMoving = false

    private let holdRepeatInterval: Duration = .milliseconds(500)

    var useLegacyFallback = false

    func attach(_ peripheral: DeskPeripheral) {
        deskPeripheral = peripheral
    }

    func detach() {
        cancelHold()
        moveTask?.cancel()
        moveTask = nil
        isMoving = false
        deskPeripheral = nil
    }

    func moveUp() {
        cancelActiveMoveIfNeeded()
        deskPeripheral?.writeCommand(DeskCommand.up)
    }

    func moveDown() {
        cancelActiveMoveIfNeeded()
        deskPeripheral?.writeCommand(DeskCommand.down)
    }

    func beginHoldUp() {
        beginHold { self.moveUp() }
    }

    func beginHoldDown() {
        beginHold { self.moveDown() }
    }

    func endHold() {
        cancelHold()
        deskPeripheral?.writeCommand(DeskCommand.stop)
    }

    func stop() {
        cancelHold()
        moveTask?.cancel()
        moveTask = nil
        isMoving = false
        deskPeripheral?.writeCommand(DeskCommand.stop)
        deskPeripheral?.writeReferenceInput(DeskCommand.referenceInputStop)
    }

    func moveToHeight(_ targetCM: Float, offsetCM: Float, currentPosition: @escaping () -> DeskPosition?) async {
        guard let deskPeripheral else { return }
        cancelHold()
        if useLegacyFallback {
            await moveToHeightLegacy(targetCM: targetCM, currentPosition: currentPosition)
            return
        }

        guard deskPeripheral.referenceInputCharacteristic != nil else {
            await moveToHeightLegacy(targetCM: targetCM, currentPosition: currentPosition)
            return
        }

        moveTask?.cancel()
        isMoving = true

        moveTask = Task {
            defer {
                isMoving = false
            }

            let moveStarted = Date()
            let moveTimeout: TimeInterval = 120

            deskPeripheral.writeCommand(DeskCommand.wakeup)
            deskPeripheral.writeCommand(DeskCommand.stop)

            let payload = DeskProtocol.referenceInputPayload(heightCM: targetCM, offsetCM: offsetCM)
            var consecutiveZeroSpeed = 0
            var stallRetries = 0

            while !Task.isCancelled {
                if Date().timeIntervalSince(moveStarted) > moveTimeout {
                    break
                }

                deskPeripheral.writeReferenceInput(payload)
                try? await Task.sleep(for: .milliseconds(100))

                guard let position = currentPosition() else { continue }
                let toleranceCM = AppConstants.LINAK.moveHeightToleranceMeters * 100

                if position.speed == 0 {
                    consecutiveZeroSpeed += 1
                } else {
                    consecutiveZeroSpeed = 0
                    stallRetries = 0
                }

                if consecutiveZeroSpeed >= AppConstants.LINAK.consecutiveZeroSpeedRequired {
                    if abs(position.heightCM - targetCM) < toleranceCM {
                        break
                    }
                    stallRetries += 1
                    if stallRetries >= AppConstants.LINAK.maxStallRetries {
                        break
                    }
                    consecutiveZeroSpeed = 0
                }
            }

            deskPeripheral.writeCommand(DeskCommand.stop)
            deskPeripheral.writeReferenceInput(DeskCommand.referenceInputStop)
        }

        await moveTask?.value
    }

    private func moveToHeightLegacy(
        targetCM: Float,
        currentPosition: @escaping () -> DeskPosition?
    ) async {
        guard let deskPeripheral else { return }
        moveTask?.cancel()
        isMoving = true

        moveTask = Task {
            defer { isMoving = false }
            var lastMove = Date.distantPast

            while !Task.isCancelled {
                guard let position = currentPosition() else {
                    try? await Task.sleep(for: .milliseconds(200))
                    continue
                }

                let tolerance: Float = 0.5
                if abs(position.heightCM - targetCM) <= tolerance, position.speed == 0 {
                    break
                }

                let now = Date()
                guard now.timeIntervalSince(lastMove) >= 0.5 else {
                    try? await Task.sleep(for: .milliseconds(100))
                    continue
                }

                if position.heightCM < targetCM - tolerance {
                    deskPeripheral.writeCommand(DeskCommand.up)
                } else if position.heightCM > targetCM + tolerance {
                    deskPeripheral.writeCommand(DeskCommand.down)
                } else {
                    break
                }
                lastMove = now
                try? await Task.sleep(for: .milliseconds(200))
            }

            deskPeripheral.writeCommand(DeskCommand.stop)
        }

        await moveTask?.value
    }

    private func beginHold(command: @escaping () -> Void) {
        moveTask?.cancel()
        moveTask = nil
        isMoving = false
        cancelHold()

        command()
        holdTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: holdRepeatInterval)
                guard !Task.isCancelled else { break }
                command()
            }
        }
    }

    private func cancelHold() {
        holdTask?.cancel()
        holdTask = nil
    }

    private func cancelActiveMoveIfNeeded() {
        guard isMoving else { return }
        moveTask?.cancel()
        moveTask = nil
        isMoving = false
        deskPeripheral?.writeCommand(DeskCommand.stop)
        deskPeripheral?.writeReferenceInput(DeskCommand.referenceInputStop)
    }
}
