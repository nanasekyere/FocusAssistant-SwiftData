//
//  SettingsView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 20/04/2024.
//

import SwiftUI
import SwiftData

/// View for adjusting Pomodoro task settings and providing feedback.
struct SettingsView: View {
    // AppStorage properties for storing task and break times
    @AppStorage("taskTime") private var storedTaskTime: Int = UserDefaults.standard.integer(forKey: "taskTime") / 60
    @AppStorage("breakTime") private var storedBreakTime: Int = UserDefaults.standard.integer(forKey: "breakTime") / 60
    @AppStorage("isOnboarding") var isOnboarding: Bool?

    @Query(filter: #Predicate<UserTask> { task in
        task.pomodoro
    })
    var pTasks: [UserTask]

    // State properties for task and break times
    @State private var taskTime: Int
    @State private var breakTime: Int
    @State private var demonstration: Bool = false
    // Range of task time values
    let taskTimeRange: [Int] = Array(10...45)

    // Range of break time values
    let breakTimeRange: [Int] = Array(3...15)

    // Initialize state properties with stored values
    init() {
        _taskTime = State(initialValue: UserDefaults.standard.integer(forKey: "taskTime") / 60)
        _breakTime = State(initialValue: UserDefaults.standard.integer(forKey: "breakTime") / 60)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.BG.ignoresSafeArea()

                VStack {
                    Form {
                        // Section for Pomodoro task settings
                        Section("Pomodoro Task Settings") {
                            // Picker for selecting task time
                            Picker("Pomodoro Task Time (rec. 25)", selection: $taskTime) {
                                ForEach(taskTimeRange, id: \.self) { number in
                                    Text("\(number) mins")
                                }
                            }
                            // Save selected task time to UserDefaults
                            .onChange(of: taskTime) { _, newValue in
                                UserDefaults.standard.set(newValue * 60, forKey: "taskTime")
                                updateDuration(duration: newValue * 60)
                            }

                            // Picker for selecting break time
                            Picker("Pomodoro Break Time (rec. 5)", selection: $breakTime) {
                                ForEach(breakTimeRange, id: \.self) { number in
                                    Text("\(number) mins")
                                }
                            }
                            // Save selected break time to UserDefaults
                            .onChange(of: breakTime) { _, newValue in
                                UserDefaults.standard.set(newValue * 60, forKey: "breakTime")
                            }
                        }
                        .listRowBackground(Color.darkPurple)

                        // Section for providing feedback
                        Section("Feedback") {
                            // Link to open feedback form in browser
                            Link("Open Feedback form", destination: URL(string: "https://forms.office.com/e/BQQejzDnNt")!)
                        }
                        .listRowBackground(Color.darkPurple)
                        .tint(.activeFaPurple)
                    }
                    .scrollContentBackground(.hidden)

                    // Button to display help (onboarding)
                    Button("Display Help") {
                        isOnboarding = true
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .padding()

                }
            }
            .navigationTitle("Settings") // Set navigation title
        }
    }

    func updateDuration(duration: Int) {
        for task in pTasks {
            task.duration = duration
        }
    }
}

// Preview for SettingsView
#Preview {
    SettingsView()
}
