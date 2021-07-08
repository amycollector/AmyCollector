//
//  Favourites.swift
//  Amelia
//
//  Created by Amy Collector on 10/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct Favourites: View {
    let favourites: [Amiibo]
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let loading: Bool
    let slot: UInt8?
    
    init(favourites: [Amiibo] = [Amiibo](), cardWidth: CGFloat, cardHeight: CGFloat, loading: Bool) {
        self.favourites = favourites
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.loading = loading
        self.slot = nil
    }
    
    init(favourites: [Amiibo] = [Amiibo](), cardWidth: CGFloat, cardHeight: CGFloat, loading: Bool, slot: UInt8?) {
        self.favourites = favourites
        self.cardWidth = cardWidth
        self.cardHeight = cardHeight
        self.loading = loading
        self.slot = slot
        
        print("Favourites slot: \(self.slot!)")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("favourites")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                Spacer()
            }
            if self.favourites.count > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(self.favourites, id: \.id) { item in
                            NavigationLink(destination: CharacterDetails(amiibo: item, slot: self.slot)) {
                                CharacterCard(item.name){
                                    WebImage(url: item.image)
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                }
                                .padding(.leading)
                                .frame(width: self.cardWidth, height: self.cardHeight)
                            }
                        }
                    }
                    .disabled(self.loading)
                    .opacity(self.loading ? 0.6 : 1.0)
                    .padding(.trailing)
                }
                .padding(.horizontal, -16)
            }
            else {
                EmptyListMessage(message: "empty_favourites") {
                    Image(systemName: "suit.heart.fill")
                        .font(.title)
                        .foregroundColor(.pink)
                }
            }
        }
    }
}

struct Favourites_Previews: PreviewProvider {
    static var previews: some View {
        Favourites(cardWidth: 375 * 0.30, cardHeight: 638 * 0.20, loading: false)
            .padding()
            .previewLayout(.fixed(width: 375, height: 300))
    }
}
