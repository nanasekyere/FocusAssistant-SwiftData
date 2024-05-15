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
                    ForEach(Array(blendedTask.sortedSubtasks.enumerated()), id: \.1.id) { index, subtask in
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
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Reset response", role: .destructive) {
                        context.delete(blendedTask)
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical)
            }
            .padding()
        }
    
        .overlay(alignment: .topTrailing, content: {
            Button(action: { 
                context.delete(blendedTask)
                dismiss()
            }, label: {
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
                    
                    ForEach(subtask.sortedDetails) { detail in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(detail.desc)
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
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserTask.self, BlendedTask.self, configurations: config)
    
    return BlendedTaskView(blendedTask: try! decodeBlendedTask(from: serviceInfo.mockTask, modelContext: container.mainContext))
        .modelContainer(container)
}

