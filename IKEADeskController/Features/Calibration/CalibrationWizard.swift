import SwiftUI

enum CalibrationStep: Int, CaseIterable {
    case welcome = 0
    case minimum
    case maximum
    case sit
    case stand
    case complete
}

@MainActor
@Observable
final class CalibrationViewModel {
    var step: CalibrationStep = .welcome
    var measuredMinCM: Float = 62
    var measuredMaxCM: Float = 125
    var sitHeightCM: Float = 72
    var standHeightCM: Float = 112
    var rawMin: UInt16 = 0
    var rawMax: UInt16 = 0

    var progress: Double {
        Double(step.rawValue) / Double(CalibrationStep.complete.rawValue)
    }
}

struct CalibrationWizard: View {
    @Bindable var appState: AppState
    @State private var model = CalibrationViewModel()
    @Environment(\.dismissWindow) private var dismissWindow

    private var isConnected: Bool {
        appState.deskManager.connectionState == .connected
    }

    private var isMoving: Bool {
        appState.deskManager.movement.isMoving
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                BrandHeader(subtitle: "Calibration")
                ProgressView(value: model.progress)
            }

            content
                .frame(maxWidth: .infinity, alignment: .leading)

            navigation
        }
        .padding(28)
        .frame(minWidth: 520, minHeight: 480)
        .wizardWindowBackground()
    }

    @ViewBuilder
    private var content: some View {
        switch model.step {
        case .welcome:
            welcomeStep
        case .minimum:
            measureStep(
                title: "Lowest position",
                subtitle: "Step 2 of 5",
                atPhysicalLimit: .bottom,
                binding: $model.measuredMinCM
            )
        case .maximum:
            measureStep(
                title: "Highest position",
                subtitle: "Step 3 of 5",
                atPhysicalLimit: .top,
                binding: $model.measuredMaxCM
            )
        case .sit:
            positionStep(
                title: "Sitting height",
                subtitle: "Step 4 of 5",
                hint: "Already know your sit height? Type it and tap Move here.",
                binding: $model.sitHeightCM
            )
        case .stand:
            positionStep(
                title: "Standing height",
                subtitle: "Step 5 of 5",
                hint: "Type your stand height (e.g. 113 cm) and let the desk move automatically.",
                binding: $model.standHeightCM
            )
        case .complete:
            completeStep
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "ruler")
                .font(.system(size: 40))
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)

            Text("We'll sync the app's height readout with your real desk.")
                .font(.body)

            VStack(alignment: .leading, spacing: 8) {
                bullet("Tape-measure the lowest and highest positions")
                bullet("Enter sit & stand heights — type a number and press Move here")
                bullet("No need to hold Up/Down if you already know your heights")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .glassCard()
    }

    private var completeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("You're all set")
                .font(.title3.weight(.semibold))

            VStack(spacing: 8) {
                summaryRow("Sit", value: model.sitHeightCM)
                summaryRow("Stand", value: model.standHeightCM)
                summaryRow("Range", value: model.measuredMinCM, suffix: "– \(Int(model.measuredMaxCM)) cm")
            }
            .glassCard()
        }
        .frame(maxWidth: .infinity)
    }

    private var navigation: some View {
        HStack {
            if model.step != .welcome {
                Button("Back") { previous() }
                    .buttonStyle(AdaptiveSecondaryButtonStyle())
            }
            Spacer()
            Button(primaryButtonTitle) { primaryAction() }
                .buttonStyle(AdaptiveProminentButtonStyle())
        }
    }

    private var primaryButtonTitle: String {
        switch model.step {
        case .welcome: "Begin"
        case .complete: "Done"
        case .stand: "Save & finish"
        default: "Continue"
        }
    }

    private func primaryAction() {
        switch model.step {
        case .welcome:
            model.step = .minimum
        case .minimum:
            captureRawMin()
            model.step = .maximum
        case .maximum:
            captureRawMax()
            model.step = .sit
        case .sit:
            model.step = .stand
        case .stand:
            finishCalibration()
            model.step = .complete
        case .complete:
            dismissWindow(id: "calibration")
        }
    }

    private func previous() {
        guard let previous = CalibrationStep(rawValue: model.step.rawValue - 1) else { return }
        model.step = previous
    }

    private func moveToTarget(_ heightCM: Float) {
        Task {
            await appState.moveToHeight(heightCM)
        }
    }

    private func captureRawMin() {
        if let raw = currentRawValue() { model.rawMin = raw }
    }

    private func captureRawMax() {
        if let raw = currentRawValue() { model.rawMax = raw }
    }

    private func currentRawValue() -> UInt16? {
        guard let height = appState.deskManager.currentPosition?.heightCM else { return nil }
        let offset = appState.deskManager.heightOffsetCM
        return UInt16(max(0, (height - offset) * 100))
    }

    private func finishCalibration() {
        let offset = model.measuredMinCM - Float(model.rawMin) / 100.0
        let calibration = DeskCalibration(
            minHeight: model.measuredMinCM,
            maxHeight: model.measuredMaxCM,
            rawMin: model.rawMin,
            rawMax: model.rawMax,
            heightOffset: offset,
            calibratedAt: .now
        )
        let uuid = appState.deskManager.savedPeripheralUUID ?? UUID()
        appState.completeCalibration(
            calibration: calibration,
            sitHeight: model.sitHeightCM,
            standHeight: model.standHeightCM,
            peripheralUUID: uuid,
            bleName: appState.activeDesk?.bleName ?? "My Desk"
        )
    }

    private enum PhysicalLimit { case bottom, top }

    private func measureStep(
        title: String,
        subtitle: String,
        atPhysicalLimit limit: PhysicalLimit,
        binding: Binding<Float>
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(title: title, subtitle: subtitle)

            let limitAction = limit == .bottom ? "Go to lowest" : "Go to highest"
            VStack(alignment: .leading, spacing: 12) {
                Text(limit == .bottom
                    ? "Move the desk fully down, then enter your tape measurement."
                    : "Move the desk fully up, then enter your tape measurement.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button(limitAction) {
                        if limit == .bottom {
                            appState.deskManager.movement.moveDown()
                        } else {
                            appState.deskManager.movement.moveUp()
                        }
                    }
                    .buttonStyle(AdaptiveSecondaryButtonStyle())
                    .disabled(!isConnected)

                    Button("Stop") { appState.stopMovement() }
                        .buttonStyle(AdaptiveSecondaryButtonStyle())
                }

                liveHeightRow(label: "App estimate (uncalibrated)")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tape measurement (cm)")
                        .font(.subheadline.weight(.medium))
                    TextField("e.g. 63", value: binding, format: .number.precision(.fractionLength(1)))
                        .textFieldStyle(.roundedBorder)
                }
            }
            .glassCard()

            DisclosureGroup("Manual up / down controls") {
                DeskControls(
                    isConnected: isConnected,
                    onBeginUp: { appState.deskManager.movement.beginHoldUp() },
                    onBeginDown: { appState.deskManager.movement.beginHoldDown() },
                    onEndHold: { appState.deskManager.movement.endHold() },
                    onStop: { appState.stopMovement() }
                )
                .padding(.top, 8)
            }
            .font(.subheadline)
        }
    }

    private func positionStep(
        title: String,
        subtitle: String,
        hint: String,
        binding: Binding<Float>
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(title: title, subtitle: subtitle)

            Text(hint)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            GoToHeightControl(
                targetCM: binding,
                useMetric: appState.useMetric,
                isMoving: isMoving,
                isConnected: isConnected,
                onMove: { moveToTarget(binding.wrappedValue) }
            )

            liveHeightRow(label: "Current height")

            DisclosureGroup("Manual up / down controls") {
                DeskControls(
                    isConnected: isConnected,
                    onBeginUp: { appState.deskManager.movement.beginHoldUp() },
                    onBeginDown: { appState.deskManager.movement.beginHoldDown() },
                    onEndHold: { appState.deskManager.movement.endHold() },
                    onStop: { appState.stopMovement() }
                )
                .padding(.top, 8)
            }
            .font(.subheadline)
        }
    }

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subtitle.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title3.weight(.semibold))
        }
    }

    @ViewBuilder
    private func liveHeightRow(label: String) -> some View {
        if let height = appState.deskManager.currentPosition?.heightCM {
            LabeledContent(label) {
                Text(UnitConverter.formatHeight(height, useMetric: appState.useMetric))
                    .font(.body.weight(.semibold).monospacedDigit())
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }

    private func summaryRow(_ title: String, value: Float, suffix: String? = nil) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let suffix {
                Text(suffix)
                    .monospacedDigit()
            } else {
                Text(UnitConverter.formatHeight(value, useMetric: appState.useMetric))
                    .monospacedDigit()
            }
        }
        .font(.subheadline)
    }
}
