//
//  RepeatPicker.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 26/04/2024.
//

import SwiftUI

struct RepeatPicker: View {
    @State var days: Int = 0
    @State var minutes: Int = 0
    @State var hour: Int = 0

    @Binding var duration: Int

    var body: some View {
        HStack(spacing: 10) {

            Menu {
                ContextMenuOptions(maxValue: 3, hint: "day") { value in
                    days = value
                }
            } label: {
                Text("\(days) day")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white)
                    .padding(10)
                    .background{
                        Rectangle()
                            .fill(.white.opacity(0.4))
                            .cornerRadius(10)
                    }
            }

            Menu {
                ContextMenuOptions(maxValue: 12, hint: "hr") { value in
                    hour = value
                }
            } label: {
                Text("\(hour) hr")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white)
                    .padding(10)
                    .padding(.horizontal, 5)
                    .background{
                        Rectangle()
                            .fill(.white.opacity(0.4))
                            .cornerRadius(10)
                    }
            }


            Menu {
                ContextMenuOptions(maxValue: 60, hint: "min") { value in
                    minutes = value
                }
            } label: {
                Text("\(minutes) min")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white)
                    .padding(10)
                    .background{
                        Rectangle()
                            .fill(.white.opacity(0.4))
                            .cornerRadius(10)
                    }
            }
        }

        .onChange(of: days) {
            duration = (hour * 3600) + (minutes * 60) + (days * 86400)
        }
        .onChange(of: minutes) {
            duration = (hour * 3600) + (minutes * 60) + (days * 86400)
        }
        .onChange(of: hour) {
            duration = (hour * 3600) + (minutes * 60) + (days * 86400)
        }
    }


    @ViewBuilder
    func ContextMenuOptions(maxValue: Int, hint: String, onClick: @escaping (Int)->()) -> some View {

        ForEach(0...maxValue,id: \.self){ value in
            Button(value == 1 ? "\(value) \(hint)" : "\(value) \(hint)s" ){
                onClick(value)
            }
        }
    }
}

#Preview {
    RepeatPicker(duration: .constant(86400))
}
