//
//  ContentView.swift
//  Rapi
//
//  Created by mario on 17/5/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .nextTrain
    
    var body: some View {
        TabBarContainerView(selectedTab: $selectedTab) {
            ZStack {
                switch selectedTab {
                case .nextTrain:
                    NextTrainView()
                case .schedule:
                    ScheduleView()
                case .settings:
                    SettingsView()
                }
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
}
