//
//  CustomIcons.swift
//  Amelia
//
//  Created by Amy Collector on 12/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct CustomIcons: View {
    @ObservedObject private var appIconManager: AppIconManager = AppIconManager()

    var body: some View {
        ScrollView {
            VStack {
                ZStack(alignment: .leading) {
                    BlurView(style: .systemThickMaterial)
                    VStack(spacing: 0) {
                        ForEach(0..<self.appIconManager.icons.count) { i in
                            Button(action: { self.appIconManager.setAppIcon(self.appIconManager.icons[i].id) }) {
                                VStack(spacing: 0) {
                                    HStack(spacing: 10) {
                                        Image(uiImage: UIImage(named: "\(self.appIconManager.icons[i].imageName)")!)
                                            .renderingMode(.original)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                        VStack(alignment: .leading) {
                                            Text("\(self.appIconManager.icons[i].displayName)")
                                            .bold()
                                            Text("\(self.appIconManager.icons[i].description)")
                                                .font(.caption)
                                                .opacity(0.7)
                                        }
                                        .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    .padding()
                                    if i != self.appIconManager.icons.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            .padding()
        }
        .navigationBarTitle("settings_custom_icon", displayMode: .inline)
    }
}

fileprivate class AppIconManager: ObservableObject {
    var icons: [AppIcon] = [
        AppIcon(id: nil, imageName: "default", displayName: "Default", description: "The default, but still good."),
        AppIcon(id: "classico", imageName: "classico", displayName: "Classico", description: "The good old days."),
        AppIcon(id: "midnight", imageName: "midnight", displayName: "Midnight", description: "What time is it again?"),
        AppIcon(id: "pride", imageName: "pride", displayName: "Rainbow", description: "Is there gold at the end?"),
        AppIcon(id: "whiteout", imageName: "whiteout", displayName: "Whiteout", description: "Can't see anything here.")
    ]
    
    func setAppIcon(_ id: String?) {
        UIApplication.shared.setAlternateIconName(id)
    }
}

fileprivate struct AppIcon {
    let id: String?
    let imageName: String
    let displayName: String
    let description: String
}

struct CustomIcons_Previews: PreviewProvider {
    static var previews: some View {
        CustomIcons()
    }
}
