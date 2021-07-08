//
//  HelpPage.swift
//  Amii
//
//  Created by Amy Collector on 20/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct Help: View {
    @Environment(\.presentationMode) var presentationMode

    private let items: [WhatsNewItemModel] = [
        WhatsNewItemModel("1.circle.fill", title: "Positioning", subtitle: "When scanning a character, make sure to scan it with the top back of your device.", supliment: Image("TagPosition")),
        WhatsNewItemModel("2.circle.fill", title: "Stay Put", subtitle: "Do not move the character away instantly once the scanning starts. You will be informed when it is complete."),
        WhatsNewItemModel("3.circle.fill", title: "Need More Help?", subtitle: "Head over to amycollector.app to discover the ways we may support you.")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(self.items, id: \.imageName) { item in
                        WhatsNewItem(item)
                            .padding(.vertical, 10)
                            .scaledToFit()
                    }
                    RoundedButton(action: { self.presentationMode.wrappedValue.dismiss() }) {
                        Text("ok_got_it")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                }
                .padding()
            }
            .navigationBarTitle("settings_need_help", displayMode: .large)
        }
    }
}

struct HelpPage_Previews: PreviewProvider {
    static var previews: some View {
        Help()
    }
}
