// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import SwiftUI

struct DockLockingSettings: View {
    @ObservedObject private var l10n = L10n.shared
    @AppStorage(DefaultsKey.dockLockingEnabled) private var enabled = false
    @AppStorage(DefaultsKey.lockedDockScreenIdentifier) private var display = DockLockDisplay.systemMain
    @AppStorage(DefaultsKey.dockLockOverrideModifier) private var modifier = DockLockModifier.option.rawValue
    @State private var screens = NSScreen.screens

    private var strings: DockLockStrings { .localized(l10n.language) }
    private var disconnected: Bool { DockLockDisplay.screen(for: display) == nil }
    private var edgeCovered: Bool {
        guard screens.count > 1, let target = DockLockDisplay.screen(for: display) else { return false }
        return DockLockGeometry.exposedIntervals(for: DockLockDisplay.frame(target),
            dockPosition: DockLockDisplay.position, allFrames: screens.map(DockLockDisplay.frame)).isEmpty
    }

    var body: some View {
        SettingsCard(title: strings.title) {
            SettingsRow(symbol: AppFeature.dockLocking.symbolName, title: strings.enable, caption: strings.caption) {
                Toggle(strings.enable, isOn: $enabled).labelsHidden()
            }
            if enabled {
                SettingsRow(symbol: "display.2", title: strings.display) {
                    Picker(strings.display, selection: $display) {
                        Text(strings.main).tag(DockLockDisplay.systemMain)
                        ForEach(screens, id: \.self) { screen in
                            if !DockLockDisplay.identifier(screen).isEmpty {
                                Text(screen.localizedName).tag(DockLockDisplay.identifier(screen))
                            }
                        }
                        if disconnected { Text(strings.disconnectedDisplay).tag(display) }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 240)
                }
                if disconnected {
                    Text(strings.disconnected).font(.caption).foregroundStyle(.secondary)
                } else if edgeCovered {
                    Text(strings.covered).font(.caption).foregroundStyle(.orange)
                }
                SettingsRow(symbol: "keyboard", title: strings.bypass, caption: strings.bypassCaption) {
                    Picker(strings.bypass, selection: $modifier) {
                        ForEach(DockLockModifier.allCases, id: \.rawValue) { key in
                            Text(key.label).tag(key.rawValue)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 180)
                }
                Text(strings.note).font(.caption).foregroundStyle(.secondary)
            }
        }
        .onChange(of: enabled) { _, _ in DockLockService.shared.syncWithPreferences() }
        .onChange(of: display) { _, _ in DockLockService.shared.syncWithPreferences() }
        .onChange(of: modifier) { _, _ in DockLockService.shared.syncWithPreferences() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
            screens = NSScreen.screens
        }
    }
}
