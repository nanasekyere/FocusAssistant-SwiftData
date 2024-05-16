//
//  BlenderChoiceView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 14/04/2024.
//

import SwiftUI
import SwiftOpenAI
import SwiftData

/// View for choosing between manual task creation and AI-based task blending.
struct BlenderChoiceView: View {
    @Environment(\.modelContext) var modelContext

    // OpenAIService instance for AI-based task blending
    private var service: OpenAIService {
        // Determine service configuration based on build environment
        #if DEBUG && targetEnvironment(simulator)
        return OpenAIServiceFactory.service(
            aiproxyPartialKey: "v1|3af3250e|1|ihchDO25XUMdu1zc",
            aiproxyDeviceCheckBypass: "4832550d-b2c7-43fa-a16b-512f0072fd9e"
        )
        #else
        return OpenAIServiceFactory.service(
            aiproxyPartialKey: "v1|3af3250e|1|ihchDO25XUMdu1zc"
        )
        #endif
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.BG.ignoresSafeArea()

                VStack {
                    // Navigation link for manual task creation
                    NavigationLink(destination: NewBlendedTaskView()) {
                        VStack {
                            Image(systemName: "pencil.line") // Icon for manual task creation
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                            Text("Create a new task with subtasks manually") // Text for manual task creation
                                .foregroundStyle(.white)
                                .padding()
                        }
                    }
                    .padding()

                    Divider() // Divider between navigation links

                    // Navigation link for AI-based task blending
                    NavigationLink(destination: BlenderView(service: service)) {
                        VStack {
                            Image(systemName: "wand.and.stars.inverse") // Icon for AI-based task blending
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                            Text("Automatically blend your task using AI") // Text for AI-based task blending
                                .foregroundStyle(.white)
                                .padding()
                        }
                    }
                    .padding()

                }
                .frame(width: 300) // Set frame width for content
            }
        }
    }
}

// Preview for BlenderChoiceView
#Preview {
    BlenderChoiceView()
}
