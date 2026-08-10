import SwiftUI

/// Scrolling danmaku overlay (UI only).
///
/// Lanes are assigned greedily: a comment takes the first lane whose previous
/// entry has fully cleared, so comments never overlap. Positions are derived
/// from the playback clock (not a timer), which keeps them in sync after seeks
/// and rate changes.
///
/// This view does **not** perform networking. Pass in comments the host app
/// already obtained through its own, separately authorized channels.
public struct DanmakuOverlay: View {
    private let comments: [DanmakuComment]
    private let time: Double
    private let opacity: Double
    private let fontSize: CGFloat
    private let duration: Double
    private let areaRatio: Double

    /// - Parameters:
    ///   - comments: preferably sorted by `time` ascending.
    ///   - time: current playback position in seconds.
    ///   - duration: seconds a scrolling comment takes to cross the screen.
    ///   - areaRatio: fraction of the height used by danmaku, from the top.
    public init(
        comments: [DanmakuComment],
        time: Double,
        opacity: Double = 0.85,
        fontSize: CGFloat = 16,
        duration: Double = 8,
        areaRatio: Double = 0.4
    ) {
        self.comments = comments
        self.time = time
        self.opacity = opacity
        self.fontSize = fontSize
        self.duration = duration
        self.areaRatio = areaRatio
    }

    private struct Placed: Identifiable {
        let id: Int64
        let c: DanmakuComment
        let lane: Int
        let progress: Double     // 0 = just entered, 1 = fully exited
    }

    public var body: some View {
        GeometryReader { geo in
            let laneH = fontSize * 1.6
            let laneCount = max(1, Int((geo.size.height * areaRatio) / laneH))
            let placed = layout(laneCount: laneCount)

            ZStack(alignment: .topLeading) {
                ForEach(placed) { p in
                    let (r, g, b) = p.c.uiColorComponents
                    Text(p.c.text)
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundStyle(Color(red: r, green: g, blue: b))
                        .shadow(color: .black.opacity(0.85), radius: 1.5, y: 0.5)
                        .lineLimit(1)
                        .fixedSize()
                        .position(
                            x: xPosition(for: p, width: geo.size.width),
                            y: CGFloat(p.lane) * laneH + laneH / 2 + 8
                        )
                }
            }
            .opacity(opacity)
            .allowsHitTesting(false)
        }
    }

    private func xPosition(for p: Placed, width: CGFloat) -> CGFloat {
        switch p.c.mode {
        case 4, 5:                       // bottom / top: centred, static
            return width / 2
        default:                         // scroll right -> left
            let travel = width + 400
            return width + 200 - travel * p.progress
        }
    }

    /// Comments currently on screen, each assigned a free lane.
    private func layout(laneCount: Int) -> [Placed] {
        let start = time - duration
        guard !comments.isEmpty else { return [] }

        var lo = 0
        var hi = comments.count - 1
        var firstIdx = comments.count
        while lo <= hi {                 // binary search first index >= start
            let mid = (lo + hi) / 2
            if comments[mid].time >= start {
                firstIdx = mid
                hi = mid - 1
            } else {
                lo = mid + 1
            }
        }

        var laneFreeAt = [Double](repeating: -.infinity, count: laneCount)
        var out: [Placed] = []
        var i = firstIdx
        while i < comments.count, comments[i].time <= time {
            let c = comments[i]
            i += 1
            let progress = (time - c.time) / duration
            guard progress >= 0, progress <= 1 else { continue }

            var lane = -1
            for l in 0..<laneCount where laneFreeAt[l] <= c.time {
                lane = l
                break
            }
            if lane < 0 { continue }     // screen saturated: drop
            laneFreeAt[lane] = c.time + duration * 0.4
            out.append(Placed(id: c.id, c: c, lane: lane, progress: progress))
            if out.count > 120 { break }
        }
        return out
    }
}
