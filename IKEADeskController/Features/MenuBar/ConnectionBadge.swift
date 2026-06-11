import SwiftUI

struct ConnectionBadge: View {
    let state: DeskConnectionState
    let deskName: String

    private var statusColor: Color {
        switch state {
        case .connected: .green
        case .connecting, .scanning: .orange
        case .disconnected: .red
        }
    }

    private var statusText: String {
        switch state {
        case .connected: "Connected"
        case .connecting: "Connecting"
        case .scanning: "Scanning"
        case .disconnected: "Disconnected"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text("\(statusText) · \(deskName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
