// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2024 ejbills (DockDoor)
// Copyright (C) 2026 Vorssaint
// Adapted from DockDoor's DockLocker.swift (https://github.com/ejbills/DockDoor).
// Modified 2026-10-15: scoped geometry types and added pointer constraints for Vorssaint.

import CoreGraphics

enum DockLockPosition: String {
    case bottom, left, right
}

struct DockLockTriggerZone: Equatable {
    let rect: CGRect
    let nudgeVector: CGVector
}

struct DockLockEdgeInterval: Equatable {
    let start: CGFloat
    let end: CGFloat

    var length: CGFloat {
        end - start
    }

    static func merge(_ intervals: [DockLockEdgeInterval]) -> [DockLockEdgeInterval] {
        guard !intervals.isEmpty else { return [] }
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [DockLockEdgeInterval] = [sorted[0]]
        for interval in sorted.dropFirst() {
            if interval.start <= merged.last!.end + 0.5 {
                merged[merged.count - 1] = DockLockEdgeInterval(
                    start: merged.last!.start,
                    end: max(merged.last!.end, interval.end)
                )
            } else {
                merged.append(interval)
            }
        }
        return merged
    }

    static func subtract(from full: DockLockEdgeInterval, removing covered: [DockLockEdgeInterval]) -> [DockLockEdgeInterval] {
        let merged = merge(covered)
        var result: [DockLockEdgeInterval] = []
        var cursor = full.start

        for interval in merged {
            if interval.start > cursor {
                let gap = DockLockEdgeInterval(start: cursor, end: min(interval.start, full.end))
                if gap.length > 0.5 { result.append(gap) }
            }
            cursor = max(cursor, interval.end)
        }

        if cursor < full.end {
            let remaining = DockLockEdgeInterval(start: cursor, end: full.end)
            if remaining.length > 0.5 { result.append(remaining) }
        }

        return result
    }
}

// MARK: - Trigger Zone Calculation

enum DockLockGeometry {
    private static let triggerDepth: CGFloat = 7
    private static let adjacencyTolerance: CGFloat = 2

    static func constrainedLocation(_ point: CGPoint, zones: [DockLockTriggerZone],
                                    bypassHeld: Bool, synthetic: Bool) -> CGPoint {
        guard !bypassHeld, !synthetic, let zone = zones.first(where: { $0.rect.contains(point) }) else {
            return point
        }
        return CGPoint(x: point.x + zone.nudgeVector.dx, y: point.y + zone.nudgeVector.dy)
    }

    /// Calculate trigger zones for all non-locked screens.
    /// All frames must be in CG global coordinates (origin top-left, Y increases downward).
    static func calculateTriggerZones(
        screenFrames: [CGRect],
        lockedScreenIndex: Int,
        dockPosition: DockLockPosition
    ) -> [DockLockTriggerZone] {
        guard screenFrames.count > 1,
              lockedScreenIndex >= 0,
              lockedScreenIndex < screenFrames.count
        else { return [] }

        // macOS refuses to place the Dock on a fully covered edge, so locking there would only strand it.
        guard !exposedIntervals(
            for: screenFrames[lockedScreenIndex],
            dockPosition: dockPosition,
            allFrames: screenFrames
        ).isEmpty else { return [] }

        var zones: [DockLockTriggerZone] = []

        for (index, frame) in screenFrames.enumerated() {
            guard index != lockedScreenIndex else { continue }

            let exposedIntervals = Self.exposedIntervals(
                for: frame,
                dockPosition: dockPosition,
                allFrames: screenFrames
            )

            for interval in exposedIntervals {
                if let zone = Self.triggerZone(
                    for: frame,
                    interval: interval,
                    dockPosition: dockPosition
                ) {
                    zones.append(zone)
                }
            }
        }

        return zones
    }

    static func exposedIntervals(
        for frame: CGRect,
        dockPosition: DockLockPosition,
        allFrames: [CGRect]
    ) -> [DockLockEdgeInterval] {
        let (edgePosition, fullInterval) = edgeInfo(for: frame, dockPosition: dockPosition)

        var coveredIntervals: [DockLockEdgeInterval] = []

        for other in allFrames {
            guard other != frame else { continue }

            guard isAdjacent(other, to: frame, at: dockPosition, edgePosition: edgePosition) else { continue }

            let otherInterval = perpendicularInterval(of: other, dockPosition: dockPosition)
            let overlapStart = max(fullInterval.start, otherInterval.start)
            let overlapEnd = min(fullInterval.end, otherInterval.end)

            if overlapEnd - overlapStart > 0.5 {
                coveredIntervals.append(DockLockEdgeInterval(start: overlapStart, end: overlapEnd))
            }
        }

        return DockLockEdgeInterval.subtract(from: fullInterval, removing: coveredIntervals)
    }

    static func relocationPath(
        lockedFrame: CGRect,
        dockPosition: DockLockPosition,
        allFrames: [CGRect]
    ) -> (start: CGPoint, end: CGPoint, push: CGVector)? {
        guard let interval = exposedIntervals(for: lockedFrame, dockPosition: dockPosition, allFrames: allFrames)
            .max(by: { $0.length < $1.length })
        else { return nil }

        let along = interval.start + min(60, interval.length / 2)
        let approach: CGFloat = 80

        switch dockPosition {
        case .bottom:
            return (CGPoint(x: along, y: lockedFrame.maxY - approach), CGPoint(x: along, y: lockedFrame.maxY - 1), CGVector(dx: 0, dy: 8))
        case .left:
            return (CGPoint(x: lockedFrame.minX + approach, y: along), CGPoint(x: lockedFrame.minX, y: along), CGVector(dx: -8, dy: 0))
        case .right:
            return (CGPoint(x: lockedFrame.maxX - approach, y: along), CGPoint(x: lockedFrame.maxX - 1, y: along), CGVector(dx: 8, dy: 0))
        }
    }

    static func screenIndexHoldingDock(
        dockRect: CGRect,
        screenFrames: [CGRect],
        dockPosition: DockLockPosition
    ) -> Int? {
        var best: (index: Int, distance: CGFloat)?

        for (index, frame) in screenFrames.enumerated() {
            let distance: CGFloat
            switch dockPosition {
            case .bottom:
                guard dockRect.midX >= frame.minX, dockRect.midX <= frame.maxX else { continue }
                distance = min(abs(frame.maxY - dockRect.minY), abs(frame.maxY - dockRect.maxY))
            case .left:
                guard dockRect.midY >= frame.minY, dockRect.midY <= frame.maxY else { continue }
                distance = min(abs(frame.minX - dockRect.maxX), abs(frame.minX - dockRect.minX))
            case .right:
                guard dockRect.midY >= frame.minY, dockRect.midY <= frame.maxY else { continue }
                distance = min(abs(frame.maxX - dockRect.minX), abs(frame.maxX - dockRect.maxX))
            }
            if best == nil || distance < best!.distance {
                best = (index, distance)
            }
        }

        return best?.index
    }

    // MARK: - Private Helpers

    private static func edgeInfo(
        for frame: CGRect,
        dockPosition: DockLockPosition
    ) -> (edgePosition: CGFloat, interval: DockLockEdgeInterval) {
        switch dockPosition {
        case .bottom:
            (frame.maxY, DockLockEdgeInterval(start: frame.minX, end: frame.maxX))
        case .left:
            (frame.minX, DockLockEdgeInterval(start: frame.minY, end: frame.maxY))
        case .right:
            (frame.maxX, DockLockEdgeInterval(start: frame.minY, end: frame.maxY))
        }
    }

    private static func isAdjacent(
        _ other: CGRect,
        to frame: CGRect,
        at dockPosition: DockLockPosition,
        edgePosition: CGFloat
    ) -> Bool {
        switch dockPosition {
        case .bottom:
            abs(other.minY - edgePosition) <= adjacencyTolerance
        case .left:
            abs(other.maxX - edgePosition) <= adjacencyTolerance
        case .right:
            abs(other.minX - edgePosition) <= adjacencyTolerance
        }
    }

    private static func perpendicularInterval(
        of frame: CGRect,
        dockPosition: DockLockPosition
    ) -> DockLockEdgeInterval {
        switch dockPosition {
        case .bottom:
            DockLockEdgeInterval(start: frame.minX, end: frame.maxX)
        case .left, .right:
            DockLockEdgeInterval(start: frame.minY, end: frame.maxY)
        }
    }

    private static func triggerZone(
        for frame: CGRect,
        interval: DockLockEdgeInterval,
        dockPosition: DockLockPosition
    ) -> DockLockTriggerZone? {
        let depth = triggerDepth
        let rect: CGRect
        let nudge: CGVector

        switch dockPosition {
        case .bottom:
            rect = CGRect(x: interval.start, y: frame.maxY - depth, width: interval.length, height: depth)
            nudge = CGVector(dx: 0, dy: -depth)
        case .left:
            rect = CGRect(x: frame.minX, y: interval.start, width: depth, height: interval.length)
            nudge = CGVector(dx: depth, dy: 0)
        case .right:
            rect = CGRect(x: frame.maxX - depth, y: interval.start, width: depth, height: interval.length)
            nudge = CGVector(dx: -depth, dy: 0)
        }

        return DockLockTriggerZone(rect: rect, nudgeVector: nudge)
    }
}

