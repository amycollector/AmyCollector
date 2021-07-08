//
//  EmptyListMessage.swift
//  Amelia
//
//  Created by Amy Collector on 11/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct EmptyListMessage<Content: View>: View {
    let message: LocalizedStringKey
    let content: Content
    
    init(message: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.message = message
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            BlurView(style: .systemThickMaterial)
            VStack(alignment: .center, spacing: 15) {
                self.content
                Text(self.message)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .lineLimit(10)
            }
            .padding(30)
            .foregroundColor(.secondary)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct EmptyListMessage_Previews: PreviewProvider {
    static var previews: some View {
        EmptyListMessage(message: "empty_favourites") {
            Image(systemName: "magnifyingglass")
        }
    }
}
