import SwiftUI

struct DeskPickerView: View {
    @Bindable var appState: AppState
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose Desk")
                .font(.title2.weight(.semibold))
            Text("Multiple LINAK desks were found nearby. Select the desk you want to control.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List(appState.deskManager.discoveredCandidates, id: \.identifier) { peripheral in
                Button(peripheral.name ?? "Unknown Desk") {
                    appState.deskManager.connectToCandidate(peripheral)
                    dismissWindow(id: "desk-picker")
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { dismissWindow(id: "desk-picker") }
            }
        }
        .padding(20)
    }
}
