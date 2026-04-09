import SwiftUI

enum EnsoTheme {
    // MARK: - Colors (Light)
    static let paper       = Color(hex: "F2EDE3")
    static let paperGrain  = Color(hex: "EDE7DB")
    static let paperShadow = Color(hex: "E4DDD0")

    static let ink         = Color(hex: "2A2826")
    static let inkWarm     = Color(hex: "3D3835")
    static let inkMid      = Color(hex: "7A756E")
    static let inkLight    = Color(hex: "A8A29A")
    static let inkFaded    = Color(hex: "C8C2B8")
    static let inkGhost    = Color(hex: "DBD6CC")
    static let inkWhisper  = Color(hex: "E8E3D9")

    static let vermillion     = Color(hex: "C4453C")
    static let vermillionSoft = Color(hex: "C4453C").opacity(0.12)

    // MARK: - Colors (Dark)
    static let paperDark       = Color(hex: "161514")
    static let paperGrainDark  = Color(hex: "1C1B19")

    static let inkDark         = Color(hex: "E4DFD6")
    static let inkWarmDark     = Color(hex: "D4CFC5")
    static let inkMidDark      = Color(hex: "8A857D")
    static let inkLightDark    = Color(hex: "5A5650")
    static let inkFadedDark    = Color(hex: "3D3A36")
    static let inkGhostDark    = Color(hex: "2A2825")
    static let inkWhisperDark  = Color(hex: "222120")

    static let vermillionDark  = Color(hex: "D4615A")

    static let syncGreen      = Color(hex: "6BA368")
    static let syncGreenDark  = Color(hex: "7CB87A")

    // MARK: - Adaptive Helper
    static func adaptive(_ light: Color, _ dark: Color, isDark: Bool) -> Color {
        isDark ? dark : light
    }

    // MARK: - Typography
    static func heroFont(_ size: CGFloat = 56) -> Font {
        .custom("ShipporiMincho-Regular", size: size)
    }

    static func valueFont(_ size: CGFloat = 22) -> Font {
        .custom("ShipporiMincho-Regular", size: size)
    }

    static func settingFont(_ size: CGFloat = 15) -> Font {
        .custom("ShipporiMincho-Regular", size: size)
    }

    static func labelFont(_ size: CGFloat = 12) -> Font {
        .custom("CormorantGaramond-LightItalic", size: size)
    }

    static func eyebrowFont(_ size: CGFloat = 10) -> Font {
        .custom("CormorantGaramond-LightItalic", size: size)
    }

    // MARK: - Spacing
    static let screenPadding: CGFloat = 28
    static let statBlockSpacing: CGFloat = 44
    static let settingGroupSpacing: CGFloat = 32
    static let settingRowPadding: CGFloat = 16
    static let conditionCellPadding: CGFloat = 18
    static let cornerRadius: CGFloat = 16
    static let progressBarHeight: CGFloat = 3
    static let weekChartHeight: CGFloat = 100

    // MARK: - Enso Canvas
    static let ensoSize: CGFloat = 260
    static let ensoCanvasScale: CGFloat = 2
    static let ensoRadius: CGFloat = 0.37
    static let ensoStartAngle: Double = -0.55 * .pi

    // MARK: - Animation Curves
    static let easeBrush = Animation.timingCurve(0.22, 1, 0.36, 1, duration: 0.7)
    static let easeInk   = Animation.timingCurve(0.33, 0, 0.2, 1, duration: 0.6)

    // MARK: - Component Sizes
    static let sealSize: CGFloat = 52
    static let themeButtonSize: CGFloat = 28
    static let stepperButtonSize: CGFloat = 30
    static let toggleWidth: CGFloat = 42
    static let toggleHeight: CGFloat = 24
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}
