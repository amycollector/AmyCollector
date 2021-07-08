//
//  CharacterCard.swift
//  Amelia
//
//  Created by Amy Collector on 09/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct CharacterCard<Content: View>: View {
    let name: String
    let content: Content
    
    init(_ text: String, @ViewBuilder content: () -> Content) {
        self.name = text
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            BlurView(style: .systemThickMaterial)
            VStack(alignment: .center,spacing: 5) {
                self.content
                Text(self.name)
                    .lineLimit(1)
                    .font(.footnote)
                    .foregroundColor(.primary)
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct CharacterCard_Previews: PreviewProvider {
    static var previews: some View {
        CharacterCard("Hello"){
            Text("Hi")
        }
        .previewLayout(.fixed(width: 200, height: 300))
    }
}
