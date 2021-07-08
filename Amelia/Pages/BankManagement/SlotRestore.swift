//
//  SlotRestore.swift
//  Amy
//
//  Created by Amy Collector on 10/08/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct SlotRestore: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private(set) var viewModel: SlotRestoreViewModel = SlotRestoreViewModel()
    @State private var showIndicator: Bool = true
    
    let slot: UInt8
    
    init(slot: UInt8) {
        self.slot = slot
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        Favourites(favourites: self.viewModel.favourites, cardWidth: (geometry.size.width * 0.30), cardHeight: (geometry.size.height * 0.20), loading: self.showIndicator, slot: self.slot)

                        SeriesSection(series: self.viewModel.ownedGrouped, title: "owned", loading: self.showIndicator, slot: self.slot, headerContent: {
                            HStack {
                                ActivityIndicator(shouldAnimate: self.$showIndicator)
                                Text("\(self.viewModel.totlaOwned)/\(self.viewModel.totalItems)")
                                .foregroundColor(.gray)
                            }
                        }, emptyListContent: {
                            EmptyListMessage(message: "empty_owned") {
                                Image(systemName: "person.2.fill")
                                    .font(.title)
                                    .foregroundColor(.green)
                            }
                        })
                    }
                    .padding()
                }
                .onAppear(perform: self.fetchData)
            }
            .navigationBarItems(trailing: VStack {
                Button("dismiss") {
                    self.dismiss()
                }
            })
            .navigationBarTitle("Restore Data to Slot \(Int(self.slot) + 1)", displayMode: .inline)
        }
    }
    
    private func fetchData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.viewModel.fetchFavourites()
            self.viewModel.fetchOwned()
            self.showIndicator = false
        }
    }
    
    private func dismiss() {
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct SlotRestore_Previews: PreviewProvider {
    static var previews: some View {
        SlotRestore(slot: 1)
    }
}
