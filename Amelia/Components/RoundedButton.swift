//
//  RoundedButton.swift
//  Amelia
//
//  Created by Amy Collector on 11/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct RoundedButton<Content: View>: View {
    let color: Color
    let action: () -> Void
    let content: Content
    
    init(color: Color = .blue, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.color = color
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: self.action) {
            ZStack(alignment: .center) {
//                BlurView(style: .systemThickMaterial)
                Rectangle()
                    .fill(self.color)
                self.content
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(height: 55)
    }
}

struct RoundedButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            RoundedButton(action: { }) {
                Text("Example")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            RoundedButton(color: .gray, action: { }) {
                Text("Example")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

struct RoundedButton_Dark_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            RoundedButton(action: { }) {
                Text("Example")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            RoundedButton(color: .gray, action: { }) {
                Text("Example")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.dark)
    }
}
