import SwiftUI
import WindowOrganizerCore

struct SettingsView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        TabView {
            ShortcutsSettingsView(controller: controller)
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            BehaviorSettingsView(preferences: $controller.preferences)
                .tabItem { Label("Behavior", systemImage: "slider.horizontal.3") }
            AppsSettingsView(controller: controller)
                .tabItem { Label("Apps", systemImage: "macwindow.on.rectangle") }
            GeneralSettingsView(controller: controller)
                .tabItem { Label("General", systemImage: "gearshape") }
        }
        .frame(width: SettingsLayoutMetrics.windowWidth)
    }
}

private struct ShortcutsSettingsView: View {
    @ObservedObject var controller: AppController
    @State private var hint: String?

    var body: some View {
        Form {
            Section {
                ForEach(OrganizerAction.allCases) { action in
                    LabeledContent(action.title) {
                        ShortcutRecorder(action: action, controller: controller, hint: $hint)
                    }
                }
            } footer: {
                Text(hint ?? "Click a shortcut and press the new keys. Esc cancels, Delete removes it.")
                    .foregroundStyle(hint == nil ? Color.secondary : Color.red)
            }

            Section {
                Button("Restore Defaults") {
                    controller.preferences.shortcuts = OrganizerPreferences.defaults.shortcuts
                    hint = nil
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct BehaviorSettingsView: View {
    @Binding var preferences: OrganizerPreferences

    var body: some View {
        Form {
            Section {
                Picker("Action scope", selection: $preferences.scope) {
                    ForEach(ActionScope.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.radioGroup)
            } footer: {
                Text("All Spaces and displays is best effort: macOS has no public API for Spaces. Force Quit Apps always asks for confirmation.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

private struct AppsSettingsView: View {
    @ObservedObject var controller: AppController
    @State private var filter = AppListFilter()

    var body: some View {
        let allApps = controller.runningApps()
        let resolver = controller.targetResolver()
        let apps = filter.apply(to: allApps, resolver: resolver)

        VStack(alignment: .leading, spacing: 10) {
            TextField("Search", text: $filter.query, prompt: Text("Search name or bundle ID"))
                .textFieldStyle(.roundedBorder)

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

            Text("**Default** follows the built-in rules: Dock apps are targeted; Finder, System Settings, menu bar apps and background processes are skipped. **Include** always targets an app, **Exclude** never touches it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

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
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .help("Default: follow the built-in rules. Include: always target. Exclude: never touch.")
                    .frame(width: 110)
                }
            }
            .alternatingRowBackgrounds()
            .frame(minHeight: SettingsLayoutMetrics.appsListMinHeight)
            .overlay {
                if apps.isEmpty {
                    Text("No matching apps")
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("Showing \(apps.count) of \(allApps.count) running")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Refresh") {
                    controller.objectWillChange.send()
                }
            }
        }
        .padding()
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var controller: AppController

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $controller.preferences.launchAtLoginEnabled)
            }

            Section {
                LabeledContent("Accessibility") {
                    if controller.isAccessibilityGranted {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        HStack {
                            Label("Not granted", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Button("Grant Access…") {
                                controller.grantAccessibility()
                            }
                        }
                    }
                }
            } header: {
                Text("Permissions")
            } footer: {
                Text("Needed for Minimize and Close. Quit and Force Quit work without it.")
                    .foregroundStyle(.secondary)
            }

            Section("Status") {
                LabeledContent("Last action") {
                    Text(controller.statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { controller.refreshPermissions() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            controller.refreshPermissions()
        }
    }
}
