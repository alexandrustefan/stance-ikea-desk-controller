import SwiftUI

struct QuickProfilePicker: View {
    let profiles: [DeskProfile]
    let activeProfile: DeskProfile?
    let onSelect: (DeskProfile) -> Void

    var body: some View {
        Menu {
            ForEach(profiles) { profile in
                Button {
                    onSelect(profile)
                } label: {
                    if profile.id == activeProfile?.id {
                        Label(profile.name, systemImage: "checkmark")
                    } else {
                        Text(profile.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: activeProfile?.icon ?? "person.crop.circle")
                Text("Profile: \(activeProfile?.name ?? "None")")
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
        }
        .menuStyle(.borderlessButton)
    }
}
