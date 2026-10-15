// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2024 ejbills (DockDoor)
// Copyright (C) 2026 Vorssaint
// Adapted from DockDoor's DockLocker.swift (https://github.com/ejbills/DockDoor).
// Modified 2026-10-15: integrated Vorssaint preferences, lifecycle and cancellable relocation.

import AppKit
import ApplicationServices

enum DockLockModifier: String, CaseIterable {
    case option, control, shift, command

    var flag: CGEventFlags {
        switch self {
        case .option: return .maskAlternate
        case .control: return .maskControl
        case .shift: return .maskShift
        case .command: return .maskCommand
        }
    }

    var label: String {
        switch self {
        case .option: return "⌥ Option"
        case .control: return "⌃ Control"
        case .shift: return "⇧ Shift"
        case .command: return "⌘ Command"
        }
    }
}

enum DockLockDisplay {
    static let systemMain = "system-main-display"

    static func identifier(_ screen: NSScreen) -> String {
        guard let id = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
              let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue()
        else { return "" }
        return CFUUIDCreateString(nil, uuid) as String
    }

    static func screen(for identifier: String) -> NSScreen? {
        if identifier == systemMain { return NSScreen.screens.first }
        guard !identifier.isEmpty else { return nil }
        return NSScreen.screens.first { self.identifier($0) == identifier }
    }

    static func frame(_ screen: NSScreen) -> CGRect {
        let top = NSScreen.screens.first?.frame.maxY ?? 0
        return CGRect(x: screen.frame.minX, y: top - screen.frame.maxY,
                      width: screen.frame.width, height: screen.frame.height)
    }

    static var position: DockLockPosition {
        let domain = UserDefaults.standard.persistentDomain(forName: "com.apple.dock")
        return DockLockPosition(rawValue: domain?["orientation"] as? String ?? "") ?? .bottom
    }
}

/// All mutable state and the event tap live on the main run loop.
final class DockLockService {
    static let shared = DockLockService()

    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var zones: [DockLockTriggerZone] = []
    private var observers: [NSObjectProtocol] = []
    private var workspaceObserver: NSObjectProtocol?
    private var dockObserver: NSObjectProtocol?
    private var settingsTimer: Timer?
    private var position = DockLockPosition.bottom
    private var relocation: DispatchWorkItem?
    private var relocationGeneration = 0
    private var relocationOrigin: CGPoint?
    private var lastSyntheticPoint: CGPoint?
    private var configuration: String?
    private var modifier = DockLockModifier.option
    private static let syntheticMarker: Int64 = 0x564F52444C

    private init() {
        SessionActivity.shared.onChange { [weak self] _ in self?.syncWithPreferences() }
    }

    func syncWithPreferences() {
        let defaults = UserDefaults.standard
        guard SessionActivitySupport.tapShouldRun(
            featureWanted: AppFeature.dockLocking.isAvailable
                && defaults.bool(forKey: DefaultsKey.dockLockingEnabled),
            accessibilityGranted: AXIsProcessTrusted(),
            sessionIsActive: SessionActivity.shared.isActive)
        else { suspend(); return }

        observeChanges()
        modifier = DockLockModifier(rawValue: defaults.string(forKey: DefaultsKey.dockLockOverrideModifier) ?? "") ?? .option
        let screens = NSScreen.screens
        let identifier = defaults.string(forKey: DefaultsKey.lockedDockScreenIdentifier) ?? DockLockDisplay.systemMain
        let position = DockLockDisplay.position
        self.position = position
        if screens.count > 1, settingsTimer == nil {
            let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
                guard let self, DockLockDisplay.position != self.position else { return }
                self.syncWithPreferences()
            }
            timer.tolerance = 0.5
            settingsTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        } else if screens.count <= 1 {
            settingsTimer?.invalidate()
            settingsTimer = nil
        }
        guard let locked = DockLockDisplay.screen(for: identifier),
              let index = screens.firstIndex(of: locked) else {
            configuration = nil
            removeTap()
            cancelRelocation()
            return
        }
        let frames = screens.map(DockLockDisplay.frame)
        zones = DockLockGeometry.calculateTriggerZones(
            screenFrames: frames, lockedScreenIndex: index, dockPosition: position)
        guard !zones.isEmpty else {
            configuration = nil
            removeTap()
            cancelRelocation()
            return
        }
        installTap()
        guard tap != nil else { configuration = nil; return }
        let next = "\(identifier)|\(position.rawValue)|\(frames)"
        if configuration != next {
            configuration = next
            scheduleRelocation(after: 1.5)
        }
    }

    func suspend() {
        settingsTimer?.invalidate()
        settingsTimer = nil
        cancelRelocation()
        removeTap()
        configuration = nil
        for observer in observers { NotificationCenter.default.removeObserver(observer) }
        observers = []
        if let workspaceObserver { NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver) }
        workspaceObserver = nil
        if let dockObserver { DistributedNotificationCenter.default().removeObserver(dockObserver) }
        dockObserver = nil
    }

    private func observeChanges() {
        guard observers.isEmpty else { return }
        for name in [NSApplication.didChangeScreenParametersNotification,
                     NSApplication.didBecomeActiveNotification,
                     UserDefaults.didChangeNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.syncWithPreferences()
            })
        }
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  app.bundleIdentifier == "com.apple.dock" else { return }
            self?.configuration = nil
            self?.syncWithPreferences()
        }
        dockObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name("com.apple.dock.prefchanged"), object: nil, queue: .main
        ) { [weak self] _ in self?.syncWithPreferences() }
    }

    private func installTap() {
        guard tap == nil else { return }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.mouseMoved.rawValue),
            callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                return Unmanaged<DockLockService>.fromOpaque(context).takeUnretainedValue()
                    .handle(type: type, event: event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()) else { return }
        self.tap = tap
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func removeTap() {
        if let tap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let tap { CFMachPortInvalidate(tap) }
        tap = nil
        source = nil
        zones = []
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if SessionActivity.shared.isActive, AXIsProcessTrusted(), let tap {
                CGEvent.tapEnable(tap: tap, enable: true)
            } else {
                DispatchQueue.main.async { [weak self] in self?.syncWithPreferences() }
            }
            return Unmanaged.passUnretained(event)
        }
        let synthetic = event.getIntegerValueField(.eventSourceUserData) == Self.syntheticMarker
        if !synthetic, relocationOrigin != nil { cancelRelocation(restorePointer: false) }
        let flags = event.flags.union(CGEventSource.flagsState(.combinedSessionState))
        event.location = DockLockGeometry.constrainedLocation(event.location, zones: zones,
            bypassHeld: flags.contains(modifier.flag), synthetic: synthetic)
        return Unmanaged.passUnretained(event)
    }

    private func scheduleRelocation(after delay: TimeInterval) {
        cancelRelocation()
        let item = DispatchWorkItem { [weak self] in self?.relocateDockIfNeeded() }
        relocation = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelRelocation(restorePointer: Bool = true) {
        relocation?.cancel()
        relocation = nil
        relocationGeneration += 1
        if restorePointer, let origin = relocationOrigin,
           let last = lastSyntheticPoint, let current = CGEvent(source: nil)?.location,
           hypot(current.x - last.x, current.y - last.y) < 2 {
            CGWarpMouseCursorPosition(origin)
        }
        relocationOrigin = nil
        lastSyntheticPoint = nil
    }

    private func relocateDockIfNeeded() {
        guard tap != nil, SessionActivity.shared.isActive, AXIsProcessTrusted(),
              !CGEventSource.flagsState(.combinedSessionState).contains(modifier.flag) else { return }
        guard ![CGMouseButton.left, .right, .center].contains(where: {
            CGEventSource.buttonState(.combinedSessionState, button: $0)
        }) else { scheduleRelocation(after: 2); return }
        let screens = NSScreen.screens
        let identifier = UserDefaults.standard.string(forKey: DefaultsKey.lockedDockScreenIdentifier) ?? DockLockDisplay.systemMain
        guard let target = DockLockDisplay.screen(for: identifier),
              let targetIndex = screens.firstIndex(of: target), let rect = dockRect(),
              let current = DockLockGeometry.screenIndexHoldingDock(
                dockRect: rect, screenFrames: screens.map(DockLockDisplay.frame), dockPosition: DockLockDisplay.position),
              current != targetIndex,
              let path = DockLockGeometry.relocationPath(lockedFrame: DockLockDisplay.frame(target),
                dockPosition: DockLockDisplay.position, allFrames: screens.map(DockLockDisplay.frame)),
              let origin = CGEvent(source: nil)?.location else { return }
        relocationOrigin = origin
        relocationGeneration += 1
        let generation = relocationGeneration
        func step(_ index: Int) {
            guard generation == self.relocationGeneration else { return }
            guard self.tap != nil, SessionActivity.shared.isActive, AXIsProcessTrusted(),
                  !CGEventSource.flagsState(.combinedSessionState).contains(self.modifier.flag),
                  ![CGMouseButton.left, .right, .center].contains(where: {
                      CGEventSource.buttonState(.combinedSessionState, button: $0)
                  }) else { self.cancelRelocation(); return }
            guard index < 15 else { self.cancelRelocation(); return }
            let t = min(CGFloat(index) / 8, 1)
            let point = CGPoint(x: path.start.x + (path.end.x - path.start.x) * t,
                                y: path.start.y + (path.end.y - path.start.y) * t)
            let delta = index <= 8
                ? CGVector(dx: (path.end.x - path.start.x) / 8, dy: (path.end.y - path.start.y) / 8)
                : path.push
            guard let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved,
                                      mouseCursorPosition: point, mouseButton: .left) else {
                self.cancelRelocation(); return
            }
            event.setIntegerValueField(.eventSourceUserData, value: Self.syntheticMarker)
            event.setIntegerValueField(.mouseEventDeltaX, value: Int64(delta.dx))
            event.setIntegerValueField(.mouseEventDeltaY, value: Int64(delta.dy))
            self.lastSyntheticPoint = point
            event.post(tap: .cghidEventTap)
            DispatchQueue.main.asyncAfter(deadline: .now() + (index == 14 ? 0.15 : 0.016)) { step(index + 1) }
        }
        step(0)
    }

    private func dockRect() -> CGRect? {
        guard let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else { return nil }
        let app = AXUIElementCreateApplication(dock.processIdentifier)
        AXUIElementSetMessagingTimeout(app, 0.1)
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXChildrenAttribute as CFString, &children) == .success,
              let elements = children as? [AXUIElement] else { return nil }
        for element in elements {
            var role: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success,
                  role as? String == kAXListRole else { continue }
            var position: CFTypeRef?
            var size: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position) == .success,
                  AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size) == .success,
                  let position, let size,
                  CFGetTypeID(position) == AXValueGetTypeID(), CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
            var point = CGPoint.zero
            var dimensions = CGSize.zero
            guard AXValueGetValue(position as! AXValue, .cgPoint, &point),
                  AXValueGetValue(size as! AXValue, .cgSize, &dimensions) else { return nil }
            return CGRect(origin: point, size: dimensions)
        }
        return nil
    }
}
