import SwiftUI
import WindowOrganizerCore

struct SettingsView: View {
    @ObservedObject var controller: AppController
    @State private var selectedTab: SettingsTab = .shortcuts

    var body: some View {
        VStack(spacing: 0) {
            Picker("Settings", selection: $selectedTab) {
                ForEach(SettingsTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(SettingsLayoutMetrics.headerPadding)

            Divider()

            Group {
                switch selectedTab {
                case .shortcuts:
                    ShortcutsSettingsView(preferences: $controller.preferences)
                case .behavior:
                    BehaviorSettingsView(preferences: $controller.preferences)
                case .apps:
                    AppsSettingsView(controller: controller)
                case .general:
                    GeneralSettingsView(controller: controller)
                }
            }
            .padding(SettingsLayoutMetrics.contentPadding)

            Spacer(minLength: 0)
        }
    }
}

private enum SettingsTab: String, CaseIterable, Identifiable {
    case shortcuts
    case behavior
    case apps
    case general

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shortcuts: "Shortcuts"
        case .behavior: "Behavior"
        case .apps: "Apps"
        case .general: "General"
        }
    }
}

private struct ShortcutsSettingsView: View {
    @Binding var preferences: OrganizerPreferences

    var body: some View {
        Form {
            ForEach(OrganizerAction.allCases) { action in
                ShortcutEditor(
                    title: action.title,
                    shortcut: Binding(
                        get: { preferences.shortcuts[action] ?? .init(key: "", modifiers: []) },
                        set: { preferences.shortcuts[action] = $0 }
                    )
                )
            }
        }
    }
}

private struct ShortcutEditor: View {
    let title: String
    @Binding var shortcut: OrganizerShortcut

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .frame(width: 170, alignment: .leading)

            TextField("Key", text: Binding(
                get: { shortcut.key },
                set: { shortcut.key = String($0.prefix(1)).uppercased() }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: 60)

            ForEach(ShortcutModifier.allCases, id: \.self) { modifier in
                Toggle(modifier.symbol, isOn: Binding(
                    get: { shortcut.modifiers.contains(modifier) },
                    set: { enabled in
                        if enabled {
                            shortcut.modifiers.insert(modifier)
                        } else {
                            shortcut.modifiers.remove(modifier)
                        }
                    }
                ))
                .toggleStyle(.button)
            }

            Text(shortcut.isValid ? shortcut.displayString : "Invalid")
                .foregroundStyle(shortcut.isValid ? Color.secondary : Color.red)
                .frame(minWidth: 90, alignment: .leading)
        }
    }
}

private struct BehaviorSettingsView: View {
    @Binding var preferences: OrganizerPreferences

    var body: some View {
        Form {
            Picker("Action scope", selection: $preferences.scope) {
                ForEach(ActionScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }

            Toggle("Confirm before force quit", isOn: $preferences.forceQuitRequiresConfirmation)
                .disabled(true)
        }
    }
}

private struct AppsSettingsView: View {
    @ObservedObject var controller: AppController
    @State private var filter = AppListFilter()

    var body: some View {
        let allApps = controller.runningApps()
        let resolver = controller.targetResolver()
        let apps = filter.apply(to: allApps, resolver: resolver)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Search", text: $filter.query, prompt: Text("Search name or bundle ID"))
                    .textFieldStyle(.roundedBorder)
                Button("Refresh") {
                    controller.objectWillChange.send()
                }
            }

            HStack {
                Picker("Kind", selection: $filter.kind) {
                    ForEach(AppListFilter.Kind.allCases) { Text($0.title).tag($0) }
                }
                Picker("Developer", selection: $filter.source) {
                    ForEach(AppListFilter.Source.allCases) { Text($0.title).tag($0) }
                }
                Picker("Status", selection: $filter.status) {
                    ForEach(AppListFilter.Status.allCases) { Text($0.title).tag($0) }
                }
            }
            .labelsHidden()

            List(apps) { app in
                HStack {
                    Image(nsImage: NSRunningApplication(processIdentifier: app.processIdentifier)?.icon
                        ?? NSWorkspace.shared.icon(for: .application))
                        .resizable()
                        .frame(width: 20, height: 20)

                    VStack(alignment: .leading) {
                        Text(app.localizedName)
                        Text(app.bundleIdentifier)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(resolver.isEligible(app) ? "Targeted" : "Skipped")
                        .font(.caption)
                        .foregroundStyle(resolver.isEligible(app) ? .green : .secondary)

                    Picker("Rule", selection: Binding(
                        get: { controller.inclusionState(for: app.bundleIdentifier) },
                        set: { controller.setInclusionState($0, for: app.bundleIdentifier) }
                    )) {
                        ForEach(AppRuleState.allCases) { state in
                            Text(state.title).tag(state)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 130)
                }
            }
            .overlay {
                if apps.isEmpty {
                    Text("No matching apps")
                        .foregroundStyle(.secondary)
                }
            }

            Text("Showing \(apps.count) of \(allApps.count) running")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $controller.preferences.launchAtLoginEnabled)

            HStack {
                Text("Accessibility")
                Spacer()
                Text(controller.permissionStatus)
                    .foregroundStyle(controller.permissionStatus == "Granted" ? .green : .red)
                Button("Request") {
                    controller.requestAccessibilityPermissionPrompt()
                }
                Button("Open Settings") {
                    controller.openAccessibilitySettings()
                }
            }

            HStack {
                Text("Bundle Identifier")
                Spacer()
                Text("com.padina.window-organizer")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Status")
                Spacer()
                Text(controller.statusMessage)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
