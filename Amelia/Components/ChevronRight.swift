//
//  ChevronRight.swift
//  Amelia
//
//  Created by Amy Collector on 12/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import SwiftUI

struct ChevronRight: View {
    var body: some View {
        VStack {
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
                .opacity(0.6)
        }
    }
}
