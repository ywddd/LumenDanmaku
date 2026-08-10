import Foundation

/// A single on-screen danmaku comment.
///
/// This package only **renders** comments. It does not fetch, sign, proxy,
/// cache, or redistribute data from any online danmaku network. The host app
/// (or the end user) supplies already-loaded `[DanmakuComment]` values.
public struct DanmakuComment: Identifiable, Sendable, Hashable {
    public let id: Int64
    /// Seconds from the start of the media.
    public let time: Double
    /// Display mode. Common convention: `1` scroll, `4` bottom, `5` top.
    public let mode: Int
    /// `0xRRGGBB`
    public let color: UInt32
    public let text: String

    public init(id: Int64, time: Double, mode: Int, color: UInt32, text: String) {
        self.id = id
        self.time = time
        self.mode = mode
        self.color = color
        self.text = text
    }

    public var uiColorComponents: (r: Double, g: Double, b: Double) {
        (
            Double((color >> 16) & 0xFF) / 255.0,
            Double((color >> 8) & 0xFF) / 255.0,
            Double(color & 0xFF) / 255.0
        )
    }
}
