//
// BlenderView.swift
// FocusAssistant
//
// Created by Nana Sekyere on 08/04/2024.
//

import SwiftUI
import SwiftData
import SwiftOpenAI



/// View for blending tasks using AI.
struct BlenderView: View {
    @Environment(\.modelContext) var context
    private let service: OpenAIService
    @Bindable private var vm: BlenderViewModel

    @State private var blendingTask: Task<Void, Never>? = nil
    @State var isShowingTask = false
    @FocusState private var isFocused: Bool
    @State var blendedTask: BlendedTask?
    @State var reset = false
    @State var showError = false
    @State private var apiError: APIError = .timeOutError


    /// Initializes the BlenderView with the given OpenAIService.
    /// - Parameter service: The OpenAIService for interacting with the OpenAI API.
    init(service: OpenAIService) {
        self.service = service
        self.vm = BlenderViewModel(service: service)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Rectangle().fill(Color.BG)
                    .ignoresSafeArea(.all)

                VStack {
                    TextField("Enter Task e.g. Make a salad", text: $vm.userPrompt)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                        .padding()

                    Button("Blend Task") {
                        withAnimation(.easeInOut(duration: 1)) {
                            isFocused = false
                            blendingTask = Task {
                                do {
                                    let actor = BackgroundSerialPersistenceActor(modelContainer: context.container)
                                    let taskJSON = try await vm.blendTask()
                                    vm.completedTask = try await actor.safeDecodeBlendedTask(from: taskJSON)
                                } catch {
                                    apiError = vm.error
                                    showError = true
                                }
                            }
                        }
                    }
                    .padding()
                    .disabled(vm.isLoading ?? false)

                    Button("Cancel", role: .destructive) {
                        blendingTask?.cancel()
                        vm.isLoading = false
                    }
                    .padding(.bottom)
                    .disabled((vm.isLoading ?? false) ? false : true)
                    .opacity((vm.isLoading ?? false) ? 100 : 0)

                    if let isLoading = vm.isLoading {
                        if isLoading {
                            ProgressView("Blending...")
                        }
                    }

                }
                .animation(.easeInOut, value: vm.completedTask == nil)
                Rectangle().fill(vm.completedTask == nil ? Color(.BG).opacity(0) : Color(.gray).opacity(0.4))
                    .blur(radius: vm.completedTask == nil ? 0 : 30)
                    .animation(.default, value: vm.completedTask == nil)
                    .ignoresSafeArea(.all)
            }
            .navigationTitle("AI Blender")
        }
        .buttonStyle(.borderedProminent)
        .animation(.bouncy, value: isShowingTask)
        .alert(isPresented: $showError, error: apiError) { error in

        } message: { error in
            Text(error.displayDescription)
        }
        .fullScreenCover(item: $vm.completedTask, onDismiss: {
            vm.isLoading = nil
            vm.userPrompt = ""
        }) { bTask in
            BlendedTaskView(blendedTask: bTask)
                .frame(width: 325, height: 675)
                .shadow(radius: 30)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .presentationBackground(Color.white.opacity(0))
        }
    }
}

#Preview {
    BlenderView(service: APIService)
        .modelContainer(for: [UserTask.self, BlendedTask.self], inMemory: true)
}
