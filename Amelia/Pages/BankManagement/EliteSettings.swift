//
//  EliteSettings.swift
//  Amy
//
//  Created by Amy Collector on 12/08/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct EliteSettings: View {
    let availableSlots: UInt8
    
    @Environment(\.presentationMode) var presentationMode
    @State private var newSlots: Double = 0
    @ObservedObject private(set) var nfc: N2EliteManager = N2EliteManager()
    
    init(availableSlots: UInt8) {
        self.availableSlots = availableSlots
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    ZStack {
                        BlurView(style: .systemThickMaterial)
                        VStack {
                            HStack {
                                Text("slots_available")
                                Spacer()
                            }
                            Slider(value: self.$newSlots, in: 1...200, step: 1, minimumValueLabel: Text("1"), maximumValueLabel: Text("200")) {
                                Text("")
                            }
                            HStack {
                                if self.newSlots == 1 {
                                    Text("New accessible slot \(Int(self.newSlots))")
                                        .font(.caption)
                                }
                                else {
                                    Text("New accessible slots \(Int(self.newSlots))")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    RoundedButton(action: { self.updateAvailableSlots() }) {
                        Text("slots_update")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .onAppear {
                    self.newSlots = Double(self.availableSlots)
                }
                .padding()
            }
            .navigationBarItems(trailing: VStack {
                Button("dismiss") {
                    self.dismiss()
                }
            })
            .navigationBarTitle("settings", displayMode: .inline)
        }
    }
    
    private func updateAvailableSlots() {
        self.nfc.performAction(.setAccessibleSlots, on: UInt8(self.newSlots)) { error in
            if error != nil {
                return
            }
        }
    }
    
    private func dismiss() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct EliteSettings_Previews: PreviewProvider {
    static var previews: some View {
        EliteSettings(availableSlots: 3)
    }
}
