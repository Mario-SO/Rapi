import SwiftUI

enum Tab: String, CaseIterable {
    case nextTrain = "Next Train"
    case schedule = "Schedule"
    case settings = "Settings"
    
    var iconName: String {
        switch self {
        case .nextTrain: return "clock.arrow.2.circlepath"
        case .schedule: return "calendar"
        case .settings: return "gearshape"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    private let tabBarHeight: CGFloat = 70
    
    // Animation states
    @State private var rotationAngle: Double = 0
    @State private var calendarBounce: CGFloat = 1.0
    @State private var settingsRotation: Double = 0
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring()) {
                        selectedTab = tab
                        
                        // Trigger animations based on tab
                        if tab == .nextTrain {
                            // Rotate clock icon
                            withAnimation(.easeInOut(duration: 0.5)) {
                                rotationAngle += 360
                            }
                        } else if tab == .schedule {
                            // Bounce calendar icon
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                                calendarBounce = 1.3
                            }
                            // Reset after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring()) {
                                    calendarBounce = 1.0
                                }
                            }
                        } else if tab == .settings {
                            // Rotate settings icon
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                                settingsRotation += 90
                            }
                            // Reset after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                withAnimation(.spring()) {
                                    settingsRotation -= 90
                                }
                            }
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        // Apply different animations based on tab type
                        Group {
                            if tab == .nextTrain {
                                Image(systemName: tab.iconName)
                                    .rotationEffect(.degrees(selectedTab == tab ? rotationAngle : 0))
                                    .animation(selectedTab == tab ? .easeInOut(duration: 0.5) : .none, value: rotationAngle)
                            } else if tab == .schedule {
                                Image(systemName: tab.iconName)
                                    .scaleEffect(selectedTab == tab ? calendarBounce : 1.0)
                            } else if tab == .settings {
                                Image(systemName: tab.iconName)
                                    .rotationEffect(.degrees(selectedTab == tab ? settingsRotation : 0))
                            }
                        }
                        .font(.system(size: 22))
                            
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == tab ? .blue : .gray)
                }
            }
        }
        .frame(height: tabBarHeight)
        .background(
            ZStack {
                // Main background with shadow
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: -2)
            }
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

struct TabBarContainerView<Content: View>: View {
    @Binding var selectedTab: Tab
    let content: Content
    
    init(selectedTab: Binding<Tab>, @ViewBuilder content: () -> Content) {
        self._selectedTab = selectedTab
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
    }
}

struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        TabBarContainerView(selectedTab: .constant(.nextTrain)) {
            Color.gray.ignoresSafeArea()
        }
    }
} 