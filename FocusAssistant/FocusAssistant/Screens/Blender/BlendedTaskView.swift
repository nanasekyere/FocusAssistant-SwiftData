//
//
//  BlendedTaskView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//
//

import SwiftUI
import SwiftData

struct BlendedTaskView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss
    
    @State var blendedTask: BlendedTask
    @State var isAnimated = false
    
    var body: some View {
        ZStack {
            Color.BG.ignoresSafeArea(.all)
            
            VStack {
                Text("Task: " + blendedTask.name)
                    .font(.title)
                    .fontWeight(.semibold)
                    .frame(alignment: .center)
                    .padding(.top, 40)
                    .padding(.horizontal, 5)
                
                List {
                    ForEach(Array(blendedTask.subtasks.enumerated()), id: \.1.id) { index, subtask in
                        SubtaskListItem(subtask: subtask, taskNo: index + 1)
                            .transition(AnyTransition.slide)
                            .animation(Animation.easeInOut.delay(Double(index) * 0.1), value: isAnimated)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color.faPurple)
                    .onAppear {
                        withAnimation { isAnimated = true }
                    }
                }
                .listStyle(.automatic)
                .listRowSpacing(10)
                .scrollContentBackground(.hidden)
                
                Spacer()
                
                HStack {
                    Button("Create Task") {
                        context.insert(blendedTask)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Reset response", role: .destructive) {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical)
            }
            .padding()
        }
    
        .overlay(alignment: .topTrailing, content: {
            Button(action: { dismiss() }, label: {
                XDismissButton()
            })
            .padding()
            .buttonStyle(.automatic)
        })
        
    }
    
    struct SubtaskListItem: View {
        let subtask: Subtask
        let taskNo: Int
        @State private var isExpanded: Bool = false
        @State private var isAnimated = false
        
        var body: some View {
            VStack(alignment: .center) {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Text("Task \(taskNo): \(subtask.name)")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                if isExpanded {
                    
                    ForEach(0...subtask.details.count - 1, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(subtask.details[index].description)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.darkPurple)
                                .cornerRadius(8)
                                .foregroundStyle(.white)
                        }
                        .shadow(radius: 5)
                        .transition(AnyTransition.slide)
                        .animation(.easeInOut, value: isAnimated)
                    }
                }
            }
            .padding(.vertical, 5)
        }
    }
}

#Preview {
    BlendedTaskView(blendedTask: mockBlendedTask)
        .modelContainer(for: BlendedTask.self, inMemory: true)
}

