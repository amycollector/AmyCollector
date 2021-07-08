//
//  ContentView.swift
//  Amelia
//
//  Created by Amy Collector on 06/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import SwiftUI
import GRDB

struct MainView: View {
    @ObservedObject private(set) var viewModel: MainViewViewModel = MainViewViewModel()
    @ObservedObject private(set) var nfc: NfcIndentify = NfcIndentify()
    
    @State private var showIdentifyResult: Bool = false
    @State private var scanResult: Amiibo? = nil
    @State private var showIndicator: Bool = true

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        Favourites(favourites: self.viewModel.favourites, cardWidth: (geometry.size.width * 0.30), cardHeight: (geometry.size.height * 0.20), loading: self.showIndicator)
                        
                        if UserDefaults.n2EliteSupport {
                            DeviceLists()
                        }

                        SeriesSection(series: self.viewModel.ownedGrouped, title: "owned", loading: self.showIndicator, headerContent: {
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
                        
                        SeriesSection(series: self.viewModel.wishListGrouped, subCategory: .wanted, title: "wish_list", loading: self.showIndicator , headerContent: {
                            HStack {
                                ActivityIndicator(shouldAnimate: self.$showIndicator)
                                NavigationLink(destination: SearchAmiibos()) {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .disabled(self.showIndicator)
                            }
                        }, emptyListContent: {
                            EmptyListMessage(message: "empty_wishlist") {
                                Image(systemName: "wand.and.stars")
                                    .font(.title)
                                    .foregroundColor(.orange)
                            }
                        })
                    }
                    .padding()                }
                .onAppear(perform: self.performInitialActions)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    self.showIndicator = true
                    self.viewModel.performDataImport()
                    self.viewModel.fetchOwned()
                    self.showIndicator = false
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("icloud_sync_done"))) { _ in
                    self.showIndicator = true
                    self.viewModel.fetchFavourites()
                    self.viewModel.fetchOwned()
                    self.viewModel.fetchWishList()
                    self.showIndicator = false
                }
            }
            .navigationBarItems(leading: VStack {
                NavigationLink(destination: Settings()) {
                    Text("settings")
                }
                .disabled(self.showIndicator)
            }, trailing: VStack {
                Button(action: self.identify) {
                    Text("identify")
                }
                .sheet(isPresented: self.$showIdentifyResult, onDismiss: { self.fetchData() }) {
                    IdentifyResult(amiibo: self.scanResult)
                }
                .disabled(self.showIndicator)
            })
            .navigationBarTitle("app_name", displayMode: .automatic)
        }
    }
    
    private func performInitialActions() {
        self.showIndicator = true
        self.viewModel.performReadMeWrite()
        self.viewModel.performDataSeeding()
        self.viewModel.performDataImport()
        self.fetchData()
        self.showIndicator = false
    }
    
    private func fetchData() {
        self.viewModel.fetchFavourites()
        self.viewModel.fetchOwned()
        self.viewModel.fetchWishList()
    }
    
    private func identify() {
        self.nfc.scan { data, _, _ in
            guard data != nil && TagUtility.validateTag(data!) else {
                self.scanResult = nil
                self.showIdentifyResult = true
                
                return
            }
            
            AmiiboRepository.shared.read { db in
                let amiibo = try? Amiibo
                    .filter(Column("id") == "\(data!.head)\(data!.tail)")
                    .fetchOne(db)
                
                self.scanResult = amiibo
                
                if self.scanResult != nil {
                    self.scanResult!.data = data
                }

                self.showIdentifyResult = true
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
