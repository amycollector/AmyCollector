//
//  CharacterListItem.swift
//  Amii
//
//  Created by Amy Collector on 15/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct CharacterListItem: View {
    let amiibo: Amiibo
    
    var body: some View {
        HStack(spacing: 3) {
            WebImage(url: self.amiibo.image)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 60)
                .padding(.vertical, 3)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("\(self.amiibo.name)")
                        .bold()
                }
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12)
                    Text("\(self.amiibo.gameSeries)")
                }
                .font(.caption)
                .opacity(0.7)
                HStack {
                    Image(systemName: "person.2.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 12)
                    Text("\(self.amiibo.amiiboSeries)")
                }
                .font(.caption)
                .opacity(0.7)
            }
            .padding(.vertical, 3)
            Spacer()
            if self.amiibo.favourite {
                VStack(spacing: 0) {
                    Spacer()
                        Image(systemName: "suit.heart.fill")
                            .foregroundColor(.pink)
                            .padding(.trailing, 6)
                    Spacer()
                }
            }
        }
    }
}
