//
// BlenderView.swift
// FocusAssistant
//
// Created by Nana Sekyere on 08/04/2024.
//

import SwiftUI
import SwiftData
import SwiftOpenAI

/// Service for interacting with the OpenAI API.
var service: OpenAIService {
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
                                await vm.blendTask()
                            }
                        }
                    }
                    .padding()
                    .disabled(vm.isLoading ?? false)

                    Button("Cancel blend", role: .destructive) {
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
                    } else {
                        Text("Blender Ready to start")
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
        .onAppear {
            vm.context = context
        }
        .buttonStyle(.borderedProminent)
        .animation(.bouncy, value: isShowingTask)
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
