//
//
//  BlenderView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//
//

import SwiftUI
import SwiftData
import SwiftOpenAI

struct BlenderView: View {
    private let service: OpenAIService
    @Bindable private var vm: BlenderViewModel
    
    
    @State private var blendingTask: Task<Void, Never>? = nil
    @State var isShowingTask = false
    @FocusState private var isFocused: Bool
    @State var blendedTask: BlendedTask?
    @State var reset = false
    
    
    init(service: OpenAIService) {
        self.service = service
        self.vm = BlenderViewModel(service: service)
    }
    
    var body: some View {
        ZStack {
            ZStack {
                Rectangle().fill(vm.blendedTask == nil ? Color(.BG) : Color(.gray).opacity(0.4))
                    .animation(.default, value: vm.blendedTask == nil)
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
                    .animation(.easeInOut, value: vm.blendedTask == nil)
                }
            
            
            
        }
        .buttonStyle(.borderedProminent)
        .animation(.bouncy, value: isShowingTask)
        .fullScreenCover(item: $vm.blendedTask, onDismiss: { vm.isLoading = nil }) { bTask in
            BlendedTaskView(blendedTask: bTask)
                .frame(width: 325, height: 675)
                .shadow(radius: 30)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .presentationBackground(Color.white.opacity(0))
        }
        
        
        
        
        
        
    }
    
    
}


#Preview {
    BlenderView(service: OpenAIServiceFactory.service(apiKey: serviceInfo.APIKey))
        .modelContainer(for: [UserTask.self, BlendedTask.self], inMemory: true)
}

