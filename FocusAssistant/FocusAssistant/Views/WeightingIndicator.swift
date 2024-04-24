//
//  WeightingIndicator.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 27/02/2024.
//

import SwiftUI

struct WeightingIndicator: View {
    
    let weight: Priority
    
    var body: some View {
        Image(systemName: getImageURL(weight))
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundStyle(.white)
    }
}

func getImageURL(_ weight: Priority) -> String {
    switch weight {
    case .low:
        return ""
    case .medium:
        return "exclamationmark.circle"
    case .high:
        return "exclamationmark.circle.fill"
    }
}

#Preview {
    WeightingIndicator(weight: .medium)
}
