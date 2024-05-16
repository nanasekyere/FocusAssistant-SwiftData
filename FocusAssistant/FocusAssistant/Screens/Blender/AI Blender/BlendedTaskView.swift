//
//  BlendedTaskView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//
//

import SwiftUI
import SwiftData

/// View displaying a blended task with its subtasks and details.
struct BlendedTaskView: View {
    @Environment(\.modelContext) var context
    @Environment(\.dismiss) var dismiss

    @State var blendedTask: BlendedTask // The blended task to display
    @State var isAnimated = false // Animation state

    var body: some View {
        ZStack {
            Color.BG.ignoresSafeArea(.all) // Background color

            VStack {
                Text("Task: " + blendedTask.name) // Display task name
                    .font(.title)
                    .fontWeight(.semibold)
                    .frame(alignment: .center)
                    .padding(.top, 40)
                    .padding(.horizontal, 5)

                // List of subtasks
                List {
                    ForEach(Array(blendedTask.sortedSubtasks.enumerated()), id: \.1.id) { index, subtask in
                        SubtaskListItem(subtask: subtask, taskNo: index + 1) // Display each subtask
                            .transition(AnyTransition.slide) // Add transition effect
                            .animation(Animation.easeInOut.delay(Double(index) * 0.1), value: isAnimated) // Add animation
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .listRowBackground(Color.faPurple) // Background color for list rows
                    .onAppear {
                        withAnimation { isAnimated = true } // Animate list appearance
                    }
                }
                .listStyle(.automatic) // Set list style
                .listRowSpacing(10) // Set spacing between list rows
                .scrollContentBackground(.hidden) // Hide scroll content background

                Spacer() // Spacer

                HStack { // Button stack
                    Button("Create Task") {
                        dismiss() // Dismiss view
                    }
                    .buttonStyle(.borderedProminent) // Apply button style

                    Button("Reset response", role: .destructive) {
                        context.delete(blendedTask) // Delete blended task
                        dismiss() // Dismiss view
                    }
                    .buttonStyle(.borderedProminent) // Apply button style
                }
                .padding(.vertical) // Add vertical padding
            }
            .padding() // Add padding to content
        }

        .overlay(alignment: .topTrailing, content: {
            Button(action: {
                context.delete(blendedTask) // Delete blended task
                dismiss() // Dismiss view
            }, label: {
                XDismissButton() // Display dismiss button
            })
            .padding() // Add padding to button
            .buttonStyle(.automatic) // Apply button style
        })

    }

    /// View displaying a subtask with its details.
    struct SubtaskListItem: View {
        let subtask: Subtask // The subtask to display
        let taskNo: Int // Task number
        @State private var isExpanded: Bool = false // Expansion state
        @State private var isAnimated = false // Animation state

        var body: some View {
            VStack(alignment: .center) {
                Button(action: {
                    withAnimation {
                        isExpanded.toggle() // Toggle expansion state
                    }
                }) {
                    Text("Task \(taskNo): \(subtask.name)") // Display subtask name
                        .font(.headline)
                        .foregroundStyle(.white) // Apply text color
                }

                if isExpanded { // If expanded
                    // Display subtask details
                    ForEach(subtask.sortedDetails) { detail in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(detail.desc) // Display detail description
                                .padding(.horizontal, 10) // Add horizontal padding
                                .padding(.vertical, 5) // Add vertical padding
                                .background(Color.darkPurple) // Set background color
                                .cornerRadius(8) // Apply corner radius
                                .foregroundStyle(.white) // Apply text color
                        }
                        .shadow(radius: 5) // Apply shadow effect
                        .transition(AnyTransition.slide) // Add transition effect
                        .animation(.easeInOut, value: isAnimated) // Add animation
                    }
                }
            }
            .padding(.vertical, 5) // Add vertical padding
        }
    }
}
