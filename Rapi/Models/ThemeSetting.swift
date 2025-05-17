import SwiftUI

// ThemeSetting enum should be defined once, globally accessible.
enum ThemeSetting: Int, CaseIterable, Identifiable {
    case system, light, dark
    var id: Self { self }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    func toColorScheme() -> ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
} 