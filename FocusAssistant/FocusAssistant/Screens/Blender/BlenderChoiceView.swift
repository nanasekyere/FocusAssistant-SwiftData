//
//  BlenderChoiceView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 14/04/2024.
//

import SwiftUI
import SwiftOpenAI
import SwiftData

struct BlenderChoiceView: View {
    @Environment(\.modelContext) var modelContext
    
    private var service: OpenAIService {
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
                    NavigationLink {
                        NewBlendedTaskView()
                    } label: {
                        VStack {
                            Image(systemName: "pencil.line")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                            Text("Create a new task with subtasks manually")
                                .foregroundStyle(.white)
                                .padding()
                        }
                        
                    }
                    .padding()

                    Divider()

                    NavigationLink {
                        BlenderView(service: service)
                    } label: {
                        VStack {
                            Image(systemName: "wand.and.stars.inverse")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                            Text("Automatically blend your task using AI")
                                .foregroundStyle(.white)
                                .padding()
                        }
                    }
                    .padding()

                }
                .frame(width: 300)
            }
        }
    }
}

#Preview {
    BlenderChoiceView()
}
