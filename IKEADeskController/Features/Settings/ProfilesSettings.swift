import SwiftUI
import UniformTypeIdentifiers

struct ProfilesSettings: View {
    @Bindable var appState: AppState
    @State private var showImporter = false
    @State private var exportDocument: ProfileExportDocument?

    private var profiles: [DeskProfile] {
        guard let desk = appState.activeDesk else {
            return appState.profileManager.profiles
        }
        let filtered = appState.profileManager.profiles(for: desk.id)
        if filtered.isEmpty {
            let defaultProfile = appState.profileManager.createProfile(
                name: "Work",
                deskDeviceId: desk.id,
                sitHeight: 72,
                standHeight: 112
            )
            return [defaultProfile]
        }
        return filtered
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Profile Management Card
            VStack(alignment: .leading, spacing: 12) {
                managementToolbar
                
                profilesTilesList
            }
            .glassCard(contentPadding: 16, cornerRadius: 16)
            
            // Profile Editor Section
            if let activeProfile = appState.profileManager.activeProfile {
                VStack(alignment: .leading, spacing: 18) {
                    
                    // Profile Info & Icon selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Profile Info")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 12) {
                                Text("Name")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                
                                TextField("Profile Name", text: nameBinding)
                                    .font(.body.weight(.semibold))
                                    .textFieldStyle(.plain)
                                    .foregroundStyle(.primary)
                            }
                            
                            Divider()
                            
                            // Horizontal Grid of icons
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Profile Icon")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(ProfileIconOptions.all, id: \.symbol) { option in
                                            let isSelected = activeProfile.icon == option.symbol
                                            Button {
                                                iconBinding.wrappedValue = option.symbol
                                            } label: {
                                                ZStack {
                                                    Circle()
                                                        .fill(isSelected ? BrandTheme.accent : Color.primary.opacity(0.04))
                                                        .frame(width: 34, height: 34)
                                                    
                                                    Image(systemName: option.symbol)
                                                        .font(.system(size: 14))
                                                        .foregroundStyle(isSelected ? .white : .primary)
                                                }
                                                .help(option.label)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                        .glassCard(contentPadding: 14, cornerRadius: 16)
                    }
                    
                    // Sit & Stand heights
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Default Heights")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 0) {
                            heightFieldRow(label: "Sitting height", binding: sitHeightBinding)
                            Divider().padding(.leading, 16)
                            heightFieldRow(label: "Standing height", binding: standHeightBinding)
                        }
                        .glassCard(contentPadding: 0, cornerRadius: 16)
                    }
                    
                    // Custom Position Presets
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Custom Positions")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 0) {
                            if customPositionsBinding.wrappedValue.isEmpty {
                                Text("No custom positions yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                ForEach(customPositionsBinding) { $position in
                                    customPositionRedesignedRow($position)
                                    if position.id != customPositionsBinding.wrappedValue.last?.id {
                                        Divider().padding(.leading, 64)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Button {
                                addCustomPosition()
                            } label: {
                                HStack {
                                    Spacer()
                                    Label("Add custom position", systemImage: "plus")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(BrandTheme.accent)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                        .glassCard(contentPadding: 0, cornerRadius: 16)
                        
                        Text("Shown as small chips below Sit & Stand in the menu bar popover.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .fileExporter(
            isPresented: Binding(
                get: { exportDocument != nil },
                set: { if !$0 { exportDocument = nil } }
            ),
            document: exportDocument ?? ProfileExportDocument(data: Data()),
            contentType: .json,
            defaultFilename: "stance-profiles"
        ) { _ in }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            guard case .success(let url) = result,
                  let data = try? Data(contentsOf: url)
            else { return }
            try? appState.profileManager.importJSON(data)
        }
    }

    // MARK: - Subviews

    private var managementToolbar: some View {
        HStack {
            Text("Select Profile")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: createProfile) {
                    Label("New", systemImage: "plus")
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BrandTheme.accent)
                
                Button {
                    if let active = appState.profileManager.activeProfile {
                        appState.profileManager.duplicateProfile(active)
                    }
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .disabled(appState.profileManager.activeProfile == nil)

                Button(role: .destructive) {
                    if let active = appState.profileManager.activeProfile {
                        appState.profileManager.deleteProfile(active)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .disabled(profiles.count <= 1)
                
                Text("|").foregroundStyle(.tertiary).font(.subheadline)
                
                Button {
                    if let data = try? appState.profileManager.exportJSON() {
                        exportDocument = ProfileExportDocument(data: data)
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .help("Export Profiles")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                
                Button { showImporter = true } label: {
                    Image(systemName: "square.and.arrow.down")
                        .help("Import Profiles")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var profilesTilesList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(profiles) { profile in
                    let isActive = profile.id == appState.profileManager.activeProfileID
                    Button {
                        appState.profileManager.setActiveProfile(profile)
                        appState.registerHotkeys()
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: profile.icon)
                                    .font(.title3)
                                    .foregroundStyle(isActive ? .white : BrandTheme.accent)
                                
                                Spacer()
                                
                                if isActive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.white)
                                }
                            }
                            
                            Text(profile.name)
                                .font(.body.weight(.bold))
                                .foregroundStyle(isActive ? .white : .primary)
                                .lineLimit(1)
                            
                            Text("Sit: \(Int(profile.sitHeight))cm · Stand: \(Int(profile.standHeight))cm")
                                .font(.caption2)
                                .foregroundStyle(isActive ? .white.opacity(0.8) : .secondary)
                        }
                        .frame(width: 140, height: 74)
                        .padding(12)
                        .background {
                            if isActive {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(BrandTheme.accent)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.primary.opacity(0.04))
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isActive ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func heightFieldRow(label: String, binding: Binding<Float>) -> some View {
        HStack {
            Text(label)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                TextField("cm", value: binding, format: .number.precision(.fractionLength(0)))
                    .textFieldStyle(.plain)
                    .frame(width: 44)
                    .multilineTextAlignment(.trailing)
                    .font(.body.weight(.bold))
                    .foregroundStyle(BrandTheme.accent)
                
                Text("cm")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func customPositionRedesignedRow(_ position: Binding<CustomPosition>) -> some View {
        HStack(spacing: 12) {
            // Icon Picker Menu Button
            Menu {
                ForEach(ProfileIconOptions.all, id: \.symbol) { option in
                    Button {
                        position.icon.wrappedValue = option.symbol
                    } label: {
                        Label(option.label, systemImage: option.symbol)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.04))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: position.icon.wrappedValue)
                        .font(.system(size: 14))
                        .foregroundStyle(BrandTheme.accent)
                }
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .frame(width: 36)
            .padding(.leading, 12)
            
            // Name field
            TextField("Position Name", text: position.name)
                .textFieldStyle(.plain)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
            
            Spacer()
            
            // Height and trash
            HStack(spacing: 8) {
                TextField("cm", value: position.height, format: .number.precision(.fractionLength(0)))
                    .textFieldStyle(.plain)
                    .frame(width: 40)
                    .multilineTextAlignment(.trailing)
                    .font(.body.weight(.bold))
                    .foregroundStyle(BrandTheme.accent)
                
                Text("cm")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                
                Button {
                    removeCustomPosition(id: position.wrappedValue.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Remove custom position")
            }
            .padding(.trailing, 12)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Bindings

    private var activeProfileIDBinding: Binding<UUID> {
        Binding(
            get: { appState.profileManager.activeProfileID ?? profiles[0].id },
            set: { id in
                guard let profile = profiles.first(where: { $0.id == id }) else { return }
                appState.profileManager.setActiveProfile(profile)
                appState.registerHotkeys()
            }
        )
    }

    private var nameBinding: Binding<String> {
        profileBinding(\.name)
    }

    private var iconBinding: Binding<String> {
        profileBinding(\.icon)
    }

    private var sitHeightBinding: Binding<Float> {
        profileBinding(\.sitHeight)
    }

    private var standHeightBinding: Binding<Float> {
        profileBinding(\.standHeight)
    }

    private var customPositionsBinding: Binding<[CustomPosition]> {
        profileBinding(\.customPositions)
    }

    private func profileBinding<Value>(_ keyPath: WritableKeyPath<DeskProfile, Value>) -> Binding<Value> {
        Binding(
            get: {
                guard let profile = appState.profileManager.activeProfile else {
                    return DeskProfile(deskDeviceId: UUID(), name: "")[keyPath: keyPath]
                }
                return profile[keyPath: keyPath]
            },
            set: { newValue in
                guard var profile = appState.profileManager.activeProfile else { return }
                profile[keyPath: keyPath] = newValue
                appState.profileManager.updateProfile(profile)
                appState.registerHotkeys()
            }
        )
    }

    // MARK: - Actions

    private func createProfile() {
        guard let deskID = appState.activeDesk?.id else { return }
        _ = appState.profileManager.createProfile(
            name: "New Profile",
            deskDeviceId: deskID,
            sitHeight: 72,
            standHeight: 112
        )
    }

    private func addCustomPosition() {
        guard var profile = appState.profileManager.activeProfile else { return }
        profile.customPositions.append(
            CustomPosition(name: "Focus", icon: "brain.head.profile", height: profile.sitHeight.rounded())
        )
        appState.profileManager.updateProfile(profile)
    }

    private func removeCustomPosition(id: UUID) {
        guard var profile = appState.profileManager.activeProfile else { return }
        profile.customPositions.removeAll { $0.id == id }
        appState.profileManager.updateProfile(profile)
    }
}

struct ProfileExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

