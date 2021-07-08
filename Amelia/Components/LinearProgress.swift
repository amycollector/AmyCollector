//
//  File.swift
//  Amii
//
//  Created by Amy Collector on 13/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import SwiftUI

public struct LinearProgress: View {
    private var value: Float
    private var color: Color = .green
    
    public init(_ value: Float) {
        self.value = value
    }
    
    public init(_ value: Float, color: Color) {
        self.value = value
        self.color = color
    }
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Capsule()
                    .foregroundColor(self.color)
                    .frame(width: geometry.size.width)
                    .opacity(0.3)
                Capsule()
                    .foregroundColor(self.color)
                    .frame(width: geometry.size.width * CGFloat(self.value))
                    .animation(.easeOut)
            }
        }.clipShape(Capsule())
    }
}

struct LinearProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LinearProgress(0.5)
                .frame(height: 10)
        }
    }
}
