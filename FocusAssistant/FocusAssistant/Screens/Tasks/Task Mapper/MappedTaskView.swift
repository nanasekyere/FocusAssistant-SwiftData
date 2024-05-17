//
// MappedTaskView.swift
// FocusAssistant
//
// Created by Nana Sekyere on 16/05/2024.
//

import SwiftUI

struct MappedTaskView: View {
    // Dismiss environment variable to dismiss the view
    @Environment(\.dismiss) private var dismiss
    // State variable to hold the mapped task
    @State var task: TaskMap
    // State variable to control the visibility of the AddTaskView
    @State private var isShowingAddView = false

    var body: some View {
        ZStack {
            // Background color
            Color.BG.ignoresSafeArea()

            VStack {
                // Display the quadrant mapping title
                Text(mapQuadrant(mapping: task.mapping))
                    .font(.title)
                    .fontWeight(.semibold)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 5)

                // Display the reason for the task mapping
                ScrollView([.vertical]) {
                    Text(task.reason)
                        .font(.subheadline)
                        .fontWeight(.light)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 20)
                }

                // Display the Eisenhower Matrix based on task mapping
                EisenhowerMatrixView(taskMapping: task.mapping)

                Spacer()

                HStack {
                    // Button to create a task, only visible for certain mappings
                    if task.mapping != 4 {
                        Button("Create Task") {
                            isShowingAddView = true
                        }
                        Spacer()
                    }

                    Button("Reset Response", role: .destructive) {
                        // Action to reset response
                    }

                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .padding()
        }
        // Present AddTaskView as a sheet when isShowingAddView is true
        .sheet(isPresented: $isShowingAddView, onDismiss: { dismiss() }, content: {
            AddTaskView(from: task)
        })
        // Display dismiss button in top-right corner
        .overlay(alignment: .topTrailing, content: {
            Button(action: {
                dismiss() // Dismiss view
            }, label: {
                XDismissButton() // Display dismiss button
            })
            .padding(2) // Add padding to button
            .buttonStyle(.automatic) // Apply button style
        })
    }

    // Helper function to map quadrant number to description
    func mapQuadrant(mapping: Int) -> String {
        switch mapping {
        case 1:
            return "Quadrant I: Urgent and Important"
        case 2:
            return "Quadrant II: Important but Not Urgent"
        case 3:
            return "Quadrant III: Urgent but Not Important"
        case 4:
            return "Quadrant IV: Neither Urgent Nor Important"
        default:
            return "Unknown"
        }
    }
}

// View to display Eisenhower Matrix based on task mapping
struct EisenhowerMatrixView: View {
    var taskMapping: Int

    var body: some View {
        VStack {
            Text("Eisenhower Matrix")
                .font(.headline)
                .padding(.vertical, 5)

            HStack {
                // Display Quadrant I and II
                QuadrantView(title: "Urgent and Important", description: "Critical tasks needing immediate attention.", isActive: taskMapping == 1)
                QuadrantView(title: "Important but Not Urgent", description: "Tasks for long-term goals and personal growth.", isActive: taskMapping == 2)
            }
            HStack {
                // Display Quadrant III and IV
                QuadrantView(title: "Urgent but Not Important", description: "Interruptions needing attention but not critical.", isActive: taskMapping == 3)
                QuadrantView(title: "Neither Urgent Nor Important", description: "Time-wasters to avoid.", isActive: taskMapping == 4)
            }
        }
        .padding()
    }
}

struct QuadrantView: View {
    var title: String
    var description: String
    var isActive: Bool

    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(isActive ? .white : .black)
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)

            Text(description)
                .font(.body)
                .foregroundColor(isActive ? .white : .secondary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .center)
                .lineLimit(nil)
        }
        .padding()
        .frame(height: 150)
        .background(isActive ? Color.blue : Color.gray.opacity(0.2))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.blue : Color.gray, lineWidth: 2)
        )
        .padding(5)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// Preview of MappedTaskView with a mock mapped task
#Preview {
    MappedTaskView(task: mockMappedTask)
}
