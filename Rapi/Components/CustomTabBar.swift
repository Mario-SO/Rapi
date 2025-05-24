import SwiftUI

struct ModernTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]
    
    @State private var tabItemWidths: [CGFloat] = []
    @State private var indicatorOffset: CGFloat = 0
    @State private var indicatorWidth: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab content background blur
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 1)
                .opacity(0.3)
            
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    ModernTabBarItem(
                        tab: tab,
                        isSelected: selectedTab == index,
                        action: {
                            withAnimation(DesignSystem.Animation.smooth) {
                                selectedTab = index
                                updateIndicator(for: index)
                            }
                        }
                    )
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    if tabItemWidths.count <= index {
                                        tabItemWidths.append(geometry.size.width)
                                    } else {
                                        tabItemWidths[index] = geometry.size.width
                                    }
                                    
                                    if index == selectedTab {
                                        updateIndicator(for: index)
                                    }
                                }
                                .onChange(of: geometry.size.width) { newWidth in
                                    tabItemWidths[index] = newWidth
                                    if index == selectedTab {
                                        updateIndicator(for: index)
                                    }
                                }
                        }
                    )
                }
            }
            .background(
                // Animated indicator
                RoundedRectangle(cornerRadius: DesignSystem.Radius.small)
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: indicatorWidth, height: 3)
                    .offset(x: indicatorOffset, y: -28)
                    .animation(DesignSystem.Animation.bounce, value: indicatorOffset)
            )
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                Rectangle()
                    .fill(DesignSystem.Colors.surface)
                    .shadow(color: DesignSystem.Shadow.medium, radius: 8, x: 0, y: -4)
            )
        }
    }
    
    private func updateIndicator(for index: Int) {
        guard index < tabItemWidths.count else { return }
        
        let itemWidth = tabItemWidths[index]
        let totalWidthBefore = tabItemWidths.prefix(index).reduce(0, +)
        
        indicatorWidth = itemWidth * 0.6 // Make indicator smaller than the tab
        indicatorOffset = totalWidthBefore + (itemWidth - indicatorWidth) / 2 - (tabItemWidths.reduce(0, +) - indicatorWidth) / 2
    }
}

struct ModernTabBarItem: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                // Icon with background
                ZStack {
                    Circle()
                        .fill(
                            isSelected ? 
                            DesignSystem.Colors.primary.opacity(0.1) : 
                            Color.clear
                        )
                        .frame(width: 44, height: 44)
                        .scaleEffect(isPressed ? 1.1 : 1.0)
                        .animation(DesignSystem.Animation.bounce, value: isPressed)
                    
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(
                            isSelected ? 
                            DesignSystem.Colors.primary : 
                            DesignSystem.Colors.textSecondary
                        )
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                        .animation(DesignSystem.Animation.bounce, value: isPressed)
                }
                
                // Label
                Text(tab.title)
                    .font(DesignSystem.Typography.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(
                        isSelected ? 
                        DesignSystem.Colors.primary : 
                        DesignSystem.Colors.textSecondary
                    )
                    .lineLimit(1)
                    .scaleEffect(isPressed ? 1.05 : 1.0)
                    .animation(DesignSystem.Animation.quick, value: isPressed)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents {
            withAnimation(DesignSystem.Animation.quick) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(DesignSystem.Animation.quick) {
                isPressed = false
            }
        }
    }
}

struct TabItem {
    let title: String
    let icon: String
    let selectedIcon: String
    
    init(title: String, icon: String, selectedIcon: String? = nil) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? "\(icon).fill"
    }
}

// MARK: - Modern Tab View
struct ModernTabView: View {
    @State private var selectedTab = 0
    
    private let tabs = [
        TabItem(title: "Next Train", icon: "clock", selectedIcon: "clock.fill"),
        TabItem(title: "Schedule", icon: "calendar", selectedIcon: "calendar.fill"),
        TabItem(title: "Routes", icon: "train.side.front.car", selectedIcon: "train.side.front.car"),
        TabItem(title: "Settings", icon: "gear", selectedIcon: "gear")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            TabView(selection: $selectedTab) {
                NextTrainView()
                    .tag(0)
                
                ScheduleView()
                    .tag(1)
                
                RouteListView()
                    .tag(2)
                
                SettingsView()
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Modern tab bar
            ModernTabBar(selectedTab: $selectedTab, tabs: tabs)
        }
        .background(DesignSystem.Colors.background)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct ModernTabView_Previews: PreviewProvider {
    static var previews: some View {
        ModernTabView()
    }
} 