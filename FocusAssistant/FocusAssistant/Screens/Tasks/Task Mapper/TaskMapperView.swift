//
// TaskMapperView.swift
// FocusAssistant
//
// Created by Nana Sekyere on 16/05/2024.
//

import SwiftUI
import SwiftData
import SwiftOpenAI

struct TaskMapperView: View {
    // State variable for the view model controlling the task mapping process
    @State var vm = TaskMapperViewModel(service: APIService)

    // State variable to manage the focus state of the text field
    @FocusState private var isFocused: Bool

    // State variable for the asynchronous task handling the mapping process
    @State private var mappingTask: Task<Void, Never>? = nil

    // State variable to store the mapped task result
    @State var mappedTask: TaskMap?

    // State variable to trigger reset of the view
    @State var reset = false

    // State variable to manage API error
    @State private var apiError = APIError.timeOutError

    // State variable to control the display of error alert
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background rectangle filling the entire view
                Rectangle().fill(Color.BG)
                    .ignoresSafeArea(.all)

                VStack {
                    // Text field for entering task name
                    TextField("Enter Task Name e.g. Make a salad", text: $vm.prompt)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .padding()

                    // Button to trigger task mapping process
                    Button("Map Task") {
                        withAnimation(.easeInOut(duration: 1)) {
                            // End editing and trigger mapping task
                            isFocused = false
                            mappingTask = Task {
                                do {
                                    // Await task mapping result
                                    try await vm.mapTask()
                                } catch {
                                    // Handle API error
                                    apiError = vm.error
                                    showError = true
                                }
                            }
                        }
                    }
                    .padding()
                    // Disable button when loading
                    .disabled(vm.isLoading ?? false)

                    // Button to cancel mapping task
                    Button("Cancel", role: .destructive) {
                        mappingTask?.cancel()
                        vm.isLoading = false
                    }
                    .padding(.bottom)
                    // Disable cancel button when not loading
                    .disabled((vm.isLoading ?? false) ? false : true)
                    // Fade out cancel button when not loading
                    .opacity((vm.isLoading ?? false) ? 100 : 0)

                    // Display loading indicator if loading
                    if let isLoading = vm.isLoading {
                        if isLoading {
                            ProgressView("Loading...")
                        }
                    }
                }
                // Set navigation title
                .navigationTitle("Task Mapper")
            }
            // Apply button style
            .buttonStyle(.borderedProminent)
            // Apply animation for showing task
            .animation(.bouncy, value: vm.isShowingTask)
            // Display alert for API error
            .alert(isPresented: $showError, error: apiError) { error in
                Button("OK") {
                    mappingTask?.cancel()
                    vm.isLoading = false
                }
            } message: { error in
                // Display error message
                Text(error.displayDescription)
            }
            // Present full screen cover for completed task mapping
            .fullScreenCover(item: $vm.completedMap, onDismiss: {
                vm.isLoading = nil
                vm.prompt = ""
            }) { mTask in
                // Present mapped task view
                MappedTaskView(task: mTask)
            }
        }
    }
}

#Preview {
    TaskMapperView()
}
