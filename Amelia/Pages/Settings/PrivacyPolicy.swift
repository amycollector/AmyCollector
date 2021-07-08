//
//  PrivacyPolicy.swift
//  Amelia
//
//  Created by Amy Collector on 12/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct PrivacyPolicy: View {
    var body: some View {
        ScrollView {
            Text("privacy_policy")
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .padding()
        }
        .navigationBarTitle("settings_privacy_policy", displayMode: .inline)
    }
}

struct PrivacyPolicy_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicy()
    }
}
