import CoreGraphics

/// Keyboard heights, shared by the real keyboard and the app's preview.
public enum KeyboardMetrics {
    /// Wider than this is the open iPhone Duo.
    public static let wideWidth: CGFloat = 700

    public static func height(forWidth width: CGFloat) -> CGFloat {
        width > wideWidth ? 250 : 280
    }
}
