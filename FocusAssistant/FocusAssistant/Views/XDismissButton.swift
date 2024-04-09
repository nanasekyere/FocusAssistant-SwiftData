//
//  XDismissButton.swift
//  FocusAssistant
//
//  Created by Nana Sekyere on 08/04/2024.
//

import SwiftUI

struct XDismissButton: View {
    var body: some View {
        ZStack{
            Circle()
                .frame(width: 20, height: 20)
                .foregroundStyle(.white)
                .opacity(0.6)
            
            Image(systemName: "xmark")
                .imageScale(.small)
                .frame(width: 34, height: 34)
                .foregroundStyle(.black)
        }
    }
}

#Preview {
    XDismissButton()
}
