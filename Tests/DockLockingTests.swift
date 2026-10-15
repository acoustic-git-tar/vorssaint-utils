// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint

import CoreGraphics
import Foundation

enum DockLockingTests {
    static func run(_ suite: TestSuite) {
        let main = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let right = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let below = CGRect(x: 0, y: 900, width: 1440, height: 900)
        let above = CGRect(x: 0, y: -900, width: 1440, height: 900)

        suite.expect(DockLockGeometry.calculateTriggerZones(screenFrames: [main],
            lockedScreenIndex: 0, dockPosition: .bottom).isEmpty,
            "a single screen never intercepts pointer movement")
        for invalid in [-1, 2] {
            suite.expect(DockLockGeometry.calculateTriggerZones(screenFrames: [main, right],
                lockedScreenIndex: invalid, dockPosition: .bottom).isEmpty,
                "a missing target never locks other screens")
        }

        let bottom = DockLockGeometry.calculateTriggerZones(screenFrames: [main, right],
            lockedScreenIndex: 0, dockPosition: .bottom)
        suite.expect(bottom.count == 1
            && bottom[0].rect == CGRect(x: 1440, y: 1073, width: 1920, height: 7)
            && bottom[0].nudgeVector == CGVector(dx: 0, dy: -7),
            "a bottom Dock nudges inward only on the other screen")
        suite.expect(!bottom.contains { $0.rect.contains(CGPoint(x: 500, y: 899)) },
            "the selected screen keeps its Dock edge accessible")
        let point = CGPoint(x: 1800, y: 1079)
        suite.expect(DockLockGeometry.constrainedLocation(point, zones: bottom,
            bypassHeld: false, synthetic: false) == CGPoint(x: 1800, y: 1072),
            "ordinary pointer movement is nudged away from another display’s trigger edge")
        suite.expect(DockLockGeometry.constrainedLocation(point, zones: bottom,
            bypassHeld: true, synthetic: false) == point,
            "holding the bypass modifier leaves pointer movement untouched")
        suite.expect(DockLockGeometry.constrainedLocation(point, zones: bottom,
            bypassHeld: false, synthetic: true) == point,
            "relocation events pass through the lock without being nudged")
        suite.expect(DockLockGeometry.constrainedLocation(CGPoint(x: 1800, y: 500), zones: bottom,
            bypassHeld: false, synthetic: false) == CGPoint(x: 1800, y: 500),
            "pointer movement away from a trigger edge is unchanged")

        let left = DockLockGeometry.calculateTriggerZones(screenFrames: [main, right],
            lockedScreenIndex: 0, dockPosition: .left)
        suite.expect(left.count == 1 && left[0].rect == CGRect(x: 1440, y: 900, width: 7, height: 180),
            "a left edge shared with a shorter screen only intercepts its exposed stretch")
        let rightZones = DockLockGeometry.calculateTriggerZones(screenFrames: [main, right],
            lockedScreenIndex: 1, dockPosition: .right)
        suite.expect(rightZones.isEmpty, "an internal right edge needs no interception")
        let separated = CGRect(x: -1600, y: -200, width: 1440, height: 900)
        for position in [DockLockPosition.left, .right] {
            let zones = DockLockGeometry.calculateTriggerZones(screenFrames: [main, separated],
                lockedScreenIndex: 0, dockPosition: position)
            suite.expect(zones.count == 1 && zones[0].rect.width == 7
                && zones[0].rect.height == 900
                && zones[0].nudgeVector.dx == (position == .left ? 7 : -7),
                "side Dock zones handle negative global coordinates")
        }

        suite.expect(DockLockGeometry.calculateTriggerZones(screenFrames: [main, below],
            lockedScreenIndex: 0, dockPosition: .bottom).isEmpty,
            "a fully covered target edge releases all locks")
        suite.expect(DockLockGeometry.relocationPath(lockedFrame: main, dockPosition: .bottom,
            allFrames: [main, below]) == nil,
            "relocation cannot strand the Dock on a covered edge")
        let stacked = DockLockGeometry.calculateTriggerZones(screenFrames: [main, above],
            lockedScreenIndex: 0, dockPosition: .bottom)
        suite.expect(stacked.isEmpty, "an adjacent screen’s covered edge is left traversable")

        let partial = CGRect(x: 400, y: 900, width: 600, height: 600)
        let intervals = DockLockGeometry.exposedIntervals(for: main, dockPosition: .bottom,
            allFrames: [main, partial])
        suite.expect(intervals == [DockLockEdgeInterval(start: 0, end: 400),
                                  DockLockEdgeInterval(start: 1000, end: 1440)],
            "partially covered edges retain both exposed stretches")
        let path = DockLockGeometry.relocationPath(lockedFrame: main, dockPosition: .bottom,
            allFrames: [main, partial])
        suite.expect(path?.end == CGPoint(x: 1060, y: 899) && path?.push == CGVector(dx: 0, dy: 8),
            "relocation uses the longest free stretch instead of a covered corner")
        let split = DockLockGeometry.calculateTriggerZones(screenFrames: [right, main, partial],
            lockedScreenIndex: 0, dockPosition: .bottom)
        suite.expect(split.count == 3 && !split.contains { $0.rect.contains(CGPoint(x: 700, y: 899)) },
            "the pointer can cross a shared edge between displays")

        let covered = [DockLockEdgeInterval(start: -20, end: 20),
                       DockLockEdgeInterval(start: 10, end: 40),
                       DockLockEdgeInterval(start: 60, end: 120)]
        suite.expect(DockLockEdgeInterval.subtract(from: .init(start: 0, end: 100), removing: covered)
            == [.init(start: 40, end: 60)],
            "overlapping coverage is merged and clipped to the screen edge")

        for position in [DockLockPosition.bottom, .left, .right] {
            let rect: CGRect
            switch position {
            case .bottom: rect = CGRect(x: 1800, y: 1020, width: 800, height: 60)
            case .left: rect = CGRect(x: 1440, y: 300, width: 60, height: 600)
            case .right: rect = CGRect(x: 3300, y: 300, width: 60, height: 600)
            }
            suite.expect(DockLockGeometry.screenIndexHoldingDock(dockRect: rect,
                screenFrames: [main, right], dockPosition: position) == 1,
                "Dock detection uses the appropriate edge for \(position.rawValue)")
        }
        suite.expect(DockLockGeometry.screenIndexHoldingDock(
            dockRect: CGRect(x: 1500, y: 900, width: 800, height: 60),
            screenFrames: [main, right], dockPosition: .bottom) == 1,
            "a Dock beyond the first display is assigned by its horizontal span")

        suite.expect(AppFeature.dockLocking.group == .windowsDock
            && AppFeature.dockLocking.enabledKeys == [DefaultsKey.dockLockingEnabled]
            && AppFeature.dockLocking.permissions == [.accessibility]
            && AppFeature.dockLocking.energyProfile == .mouse
            && !AppFeature.dockLocking.installedByDefault,
            "Dock Locking is an opt-in Windows and Dock feature with honest permissions and cost")
        suite.expect(AppFeature.dockLocking.settingsDestination
            == FeatureSettingsDestination(.dock, sectionAnchor: .dockLocking),
            "the feature opens its own Dock settings section")
        let backupKeys = SettingsBackupSupport.exportKeys()
        suite.expect([DefaultsKey.dockLockingEnabled, DefaultsKey.lockedDockScreenIdentifier,
                      DefaultsKey.dockLockOverrideModifier, AppFeature.dockLocking.availabilityKey]
            .allSatisfy(backupKeys.contains), "Dock locking preferences are included in backup")
        for language in AppLanguage.allCases {
            let strings = DockLockStrings.localized(language)
            suite.expect(Mirror(reflecting: strings).children.allSatisfy {
                ($0.value as? String)?.isEmpty == false
            }, "all Dock Locking controls and display states have labels in \(language.rawValue)")
        }
    }
}
