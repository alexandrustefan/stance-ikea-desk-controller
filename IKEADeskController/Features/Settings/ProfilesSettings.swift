import SwiftUI
import UniformTypeIdentifiers

struct ProfilesSettings: View {
    @Bindable var appState: AppState
    @State private var showImporter = false
    @State private var exportDocument: ProfileExportDocument?

    private var profiles: [DeskProfile] {
        guard let deskId = appState.activeDesk?.id else {
            return appState.profileManager.profiles
        }
        let filtered = appState.profileManager.profiles(for: deskId)
        return filtered.isEmpty ? appState.profileManager.profiles : filtered
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            managementBar

            Form {
                if let desk = appState.activeDesk {
                    Section {
                        LabeledContent("Desk") {
                            Text(desk.title)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Picker("Active profile", selection: activeProfileIDBinding) {
                        ForEach(profiles) { profile in
                            Label(profile.name, systemImage: profile.icon)
                                .tag(profile.id)
                        }
                    }
                }

                if appState.profileManager.activeProfile != nil {
                    Section("Profile") {
                        TextField("Name", text: nameBinding)

                        Picker("Icon", selection: iconBinding) {
                            ForEach(ProfileIconOptions.all, id: \.symbol) { option in
                                Label(option.label, systemImage: option.symbol)
                                    .tag(option.symbol)
                            }
                        }
                    }

                    Section("Sit & stand") {
                        heightRow(label: "Sit height", binding: sitHeightBinding)
                        heightRow(label: "Stand height", binding: standHeightBinding)
                    }

                    Section {
                        if customPositionsBinding.wrappedValue.isEmpty {
                            Text("No custom positions yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(customPositionsBinding) { $position in
                                customPositionRow($position)
                            }
                        }

                        Button {
                            addCustomPosition()
                        } label: {
                            Label("Add custom position", systemImage: "plus")
                        }
                    } header: {
                        Text("Custom positions")
                    } footer: {
                        Text("Shown as small chips below Sit & Stand in the menu bar popover.")
                    }
                }
            }
            .formStyle(.grouped)
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

    // MARK: - Toolbar

    private var managementBar: some View {
        HStack(spacing: 8) {
            Button { createProfile() } label: {
                Label("New", systemImage: "plus")
            }

            Button {
                if let active = appState.profileManager.activeProfile {
                    appState.profileManager.duplicateProfile(active)
                }
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }

            Button(role: .destructive) {
                if let active = appState.profileManager.activeProfile {
                    appState.profileManager.deleteProfile(active)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .disabled(profiles.count <= 1)

            Spacer()

            Button {
                if let data = try? appState.profileManager.exportJSON() {
                    exportDocument = ProfileExportDocument(data: data)
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }

            Button { showImporter = true } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
    }

    // MARK: - Rows

    private func heightRow(label: String, binding: Binding<Float>) -> some View {
        LabeledContent(label) {
            HStack(spacing: 6) {
                TextField("cm", value: binding, format: .number.precision(.fractionLength(0)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 56)
                    .multilineTextAlignment(.trailing)
                Text("cm")
                    .foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .leading)
            }
        }
    }

    private func customPositionRow(_ position: Binding<CustomPosition>) -> some View {
        HStack(spacing: 10) {
            Picker("", selection: position.icon) {
                ForEach(ProfileIconOptions.all, id: \.symbol) { option in
                    Image(systemName: option.symbol).tag(option.symbol)
                }
            }
            .labelsHidden()
            .frame(width: 40)

            TextField("Name", text: position.name)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 4) {
                TextField("cm", value: position.height, format: .number.precision(.fractionLength(0)))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 52)
                    .multilineTextAlignment(.trailing)
                Text("cm")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                removeCustomPosition(id: position.wrappedValue.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Remove")
        }
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
