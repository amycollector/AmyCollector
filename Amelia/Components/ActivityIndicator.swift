//
//  ActivityIndicator.swift
//  Amy
//
//  Created by Amy Collector on 21/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI
import UIKit

struct ActivityIndicator: UIViewRepresentable {
    @Binding var shouldAnimate: Bool

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let activity = UIActivityIndicatorView()
        
        return activity
    }
    
    func updateUIView(_ activity: UIActivityIndicatorView, context: Context) {
        if self.shouldAnimate {
            activity.startAnimating()
        }
        else {
            activity.stopAnimating()
        }
    }
}
