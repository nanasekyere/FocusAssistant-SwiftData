//
//  OnboardingView.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 20/04/2024.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        ZStack {
            Color.BG.ignoresSafeArea()
            TabView {
                OnboardingPage(imageName: "brain.fill", title: "Welcome To FocusAssistant", description: "A time management app tailored for adults with ADHD, suitable for all.")
                OnboardingPage(imageName: "checklist", title: "Tasks", description: "Tasks in focus assistant are simple to use. You set the name of the task, the time it should start, and the duration of the task")
                OnboardingPage(imageName: "alarm", title: "Pomodoro Tasks", description: "Pomodoro tasks are tasks you create for longer activities, such as coding an app.\n\n You work for 25 minutes and take a 5 minute break, FocusAssistant handles all this for you so all you have to do is start the task and get to work.\n\n This helps maximise productivity for more boring tasks")
                OnboardingPage(imageName: "tornado", title: "Task Blender", description: "The task blender lets you break down bigger tasks into smaller more manageable subtasks.\n\n Blended Tasks are automatically configured to be Pomodoro Tasks, and as you are working you can check and uncheck the subtasks you have completed.\n\n You can choose to either create your own tasks and subtasks or use the AI feature to generate your subtasks based on the task you prompt")

                OnboardingPage(imageName: "button.vertical.left.press.fill", title: "Get Started", description: "Enter your first name then press the button to get started", lastPage: true)

            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        }
    }
}

struct OnboardingPage: View {
    @AppStorage("isOnboarding") var isOnboarding: Bool?

    let imageName: String
    let title: String
    let description: String

    var lastPage: Bool?
    @AppStorage("userName") var name: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100, alignment: .center)
            Text(title)
                .font(.title.bold())
                .frame(alignment: .center)
            Text(description)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if lastPage == true {
                TextField("Enter your first name", text: $name)

                Button("Continue to app") {
                    isOnboarding = false
                    UserDefaults.standard.setValue(1500, forKey: "taskTime")
                    UserDefaults.standard.setValue(5, forKey: "breakTime")
                }
                .disabled(name.count < 3)
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .padding(40)
    }
}

#Preview {
    OnboardingView()
}
