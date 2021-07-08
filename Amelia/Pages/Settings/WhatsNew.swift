//
//  WhatsNewItem.swift
//  Amii
//
//  Created by Amy Collector on 15/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct WhatsNew: View {
    @Environment(\.presentationMode) var presentationMode

    private let items: [WhatsNewItemModel] = [
        WhatsNewItemModel("speedometer", title: "Faster Identification", subtitle: "The AmiiboAPI data is now bundled in for faster identification and less data requests."),
        WhatsNewItemModel("arrow.down.doc.fill", title: "Backup & Restore", subtitle: "Backup and restore your Amiibo data to another NFC tag."),
        WhatsNewItemModel("arrow.clockwise.icloud.fill", title: "iCloud Sync", subtitle: "Take your back ups and wish list anywhere with iCloud synchronisation."),
        WhatsNewItemModel("wand.and.stars.inverse", title: "Wish List", subtitle: "Keep track of the Amiibos you want by adding them to your Wish List."),
        WhatsNewItemModel("photo", title: "Inline Image", subtitle: "Easily distinguish your Amiibos with inline images on the Characters list."),
        WhatsNewItemModel("quote.bubble.fill", title: "Basic Help", subtitle: "Access basic help and tips within the application."),
        WhatsNewItemModel("paintbrush.fill", title: "Custom Icons", subtitle: "Set custom icons to suit your mood.")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    ForEach(self.items, id: \.imageName) { item in
                        WhatsNewItem(item)
                            .padding(.vertical, 10)
                    }
                    RoundedButton(action: { self.presentationMode.wrappedValue.dismiss() }) {
                        Text("ok_lets_go")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarTitle("What's New?", displayMode: .large)
        }
    }
}

struct WhatsNewItemModel {
    init (_ imageName: String, title: String, subtitle: String, tint: Color = .blue, supliment: Image? = nil) {
        self.imageName = imageName
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.supliment = supliment
    }
    
    var imageName: String
    var title: String
    var subtitle: String
    var tint: Color
    var supliment: Image?
}

struct WhatsNewItem: View {
    init(_ item: WhatsNewItemModel) {
        self.item = item
    }

    private var item: WhatsNewItemModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack {
                Image(systemName: self.item.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30, alignment: .top)
                    .foregroundColor(item.tint)
                Spacer()
            }
            VStack(alignment: .leading) {
                Text(self.item.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(3)
                    .padding(.bottom, 3)
                Text(self.item.subtitle)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.body)
                    .lineLimit(10)
                if item.supliment != nil {
                    HStack {
                        Spacer()
                        item.supliment?.resizable().scaledToFit()
                        Spacer()
                    }
                }
            }
            .padding(.leading, 5)
            Spacer()
        }
    }
}

struct WhatsNewItem_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewItem(WhatsNewItemModel("globe", title: "Global", subtitle: "Available globally and it might be a bit long as we need to see how it looks"))
    }
}
