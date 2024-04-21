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
                        BlenderView(service: OpenAIServiceFactory.service(apiKey: serviceInfo.APIKey))
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
