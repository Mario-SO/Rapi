import SwiftUI

// MARK: - Design System
// Inspired by Teenage Engineering and Linear app design principles

struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Monochrome palette (inspired by Teenage Engineering)
        static let background = Color(hex: "FAFAFA")
        static let surface = Color(hex: "FFFFFF")
        static let surfaceElevated = Color(hex: "F8F9FA")
        
        // Text
        static let textPrimary = Color(hex: "1A1A1A")
        static let textSecondary = Color(hex: "6B7280")
        static let textTertiary = Color(hex: "9CA3AF")
        
        // Brand
        static let primary = Color(hex: "2563EB")
        static let primaryLight = Color(hex: "3B82F6")
        static let success = Color(hex: "10B981")
        static let warning = Color(hex: "F59E0B")
        static let error = Color(hex: "EF4444")
        
        // Accent (inspired by TE orange)
        static let accent = Color(hex: "FF5722")
        static let accentLight = Color(hex: "FF7043")
        
        // Borders
        static let border = Color(hex: "E5E7EB")
        static let borderLight = Color(hex: "F3F4F6")
    }
    
    // MARK: - Typography
    struct Typography {
        // Display (for hero sections)
        static let displayLarge = Font.system(size: 32, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
        
        // Headings
        static let headingLarge = Font.system(size: 24, weight: .bold, design: .rounded)
        static let headingMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headingSmall = Font.system(size: 16, weight: .semibold, design: .rounded)
        
        // Body
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // Mono (for times, codes)
        static let monoLarge = Font.system(size: 16, weight: .medium, design: .monospaced)
        static let monoMedium = Font.system(size: 14, weight: .medium, design: .monospaced)
        static let monoSmall = Font.system(size: 12, weight: .regular, design: .monospaced)
        
        // Captions
        static let caption = Font.system(size: 11, weight: .medium, design: .default)
        static let captionMono = Font.system(size: 11, weight: .medium, design: .monospaced)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let small = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let large = Color.black.opacity(0.15)
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let bounce = SwiftUI.Animation.interpolatingSpring(
            stiffness: 300,
            damping: 20
        )
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
extension View {
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.medium)
            .shadow(color: DesignSystem.Shadow.small, radius: 4, x: 0, y: 2)
    }
    
    func elevatedCardStyle() -> some View {
        self
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.Radius.large)
            .shadow(color: DesignSystem.Shadow.medium, radius: 8, x: 0, y: 4)
    }
    
    func primaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.primary)
            .cornerRadius(DesignSystem.Radius.medium)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .font(DesignSystem.Typography.bodyMedium)
            .foregroundColor(DesignSystem.Colors.primary)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.medium)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
    }
    
    func subtleAnimation() -> some View {
        self.animation(DesignSystem.Animation.smooth, value: UUID())
    }
} 