//
//  SettingsView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 20/04/2024.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("taskTime") private var storedTaskTime: Int = UserDefaults.standard.integer(forKey: "taskTime") / 60
    @AppStorage("breakTime") private var storedBreakTime: Int = UserDefaults.standard.integer(forKey: "breakTime") / 60
    @AppStorage("isOnboarding") var isOnboarding: Bool?

    @State private var taskTime: Int
    @State private var breakTime: Int

    let taskTimeRange: [Int] = Array(10...45)

    let breakTimeRange: [Int] = Array(3...15)

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
                        Section("Pomodoro Task Settings") {
                            Picker("Pomodoro Task Time (rec. 25)", selection: $taskTime) {
                                ForEach(taskTimeRange, id: \.self) { number in
                                    Text("\(number) mins")
                                }
                            }
                            .onChange(of: taskTime) { oldValue, newValue in
                                UserDefaults.standard.set(newValue * 60, forKey: "taskTime")
                            }

                            Picker("Pomodoro Break Time (rec. 5)", selection: $breakTime) {
                                ForEach(breakTimeRange, id: \.self) { number in
                                    Text("\(number) mins")
                                }
                            }
                            .onChange(of: breakTime) { oldValue, newValue in
                                UserDefaults.standard.set(newValue * 60, forKey: "breakTime")
                            }

                        }
                        .listRowBackground(Color.darkPurple)

                        Section("Feedback") {
                            Link("Open Feedback form", destination: URL(string: "https://forms.office.com/e/BQQejzDnNt")!)
                        }
                        .listRowBackground(Color.darkPurple)
                        .tint(.activeFaPurple)
                    }
                    .scrollContentBackground(.hidden)

                    Button("Display Help") {
                        isOnboarding = true
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .padding()

                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
