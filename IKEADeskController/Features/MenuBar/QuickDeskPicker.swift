import SwiftUI

struct QuickDeskPicker: View {
    let desks: [DeskDevice]
    let activeDesk: DeskDevice?
    let connectedPeripheralUUID: UUID?
    let onSelect: (DeskDevice) -> Void

    var body: some View {
        Menu {
            ForEach(desks) { desk in
                Button {
                    onSelect(desk)
                } label: {
                    HStack {
                        if desk.id == activeDesk?.id {
                            Label(desk.title, systemImage: "checkmark")
                        } else {
                            Text(desk.title)
                        }
                        if connectedPeripheralUUID == desk.peripheralUUID {
                            Text("• connected")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "table.furniture.fill")
                Text(activeDesk?.title ?? "No desk")
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
        }
        .menuStyle(.borderlessButton)
    }
}
