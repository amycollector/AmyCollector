//
//  Devices.swift
//  Amy
//
//  Created by Amy Collector on 24/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct DeviceLists: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("devices")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                Spacer()
            }
            ZStack {
                BlurView(style: .systemThickMaterial)
                VStack(spacing: 0) {
                    NavigationLink(destination: BankManagement()) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.grid.3x2")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                                .opacity(0.7)
                            Text("n2_elite")
                                .lineLimit(1)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            ChevronRight()
                        }
                        .padding(.horizontal)
                        .frame(height: 55)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

struct Devices_Previews: PreviewProvider {
    static var previews: some View {
        DeviceLists()
    }
}
