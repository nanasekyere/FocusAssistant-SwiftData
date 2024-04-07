//
//  TabView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 07/04/2024.
//

import SwiftUI

struct FocusAssistantTabs: View {
    var body: some View {
        TabView {
            TaskView()
                .tabItem { Label("Tasks", systemImage: "note.text") }
            
        }
    }
}

#Preview {
    FocusAssistantTabs()
}
