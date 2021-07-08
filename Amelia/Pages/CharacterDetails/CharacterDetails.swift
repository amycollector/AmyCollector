//
//  CharacterDetails.swift
//  Amelia
//
//  Created by Amy Collector on 10/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import DeviceKit
import GRDB

struct CharacterDetails: View {
    @ObservedObject private(set) var nfcWrite: NfcWrite = NfcWrite()
    @ObservedObject private(set) var nfcIdentify: NfcIndentify = NfcIndentify()

    let amiibo: Amiibo
    let slot: UInt8?
    
    init(amiibo: Amiibo) {
        self.amiibo = amiibo
        self.slot = nil
    }
    
    init(amiibo: Amiibo, slot: UInt8?) {
        self.amiibo = amiibo
        self.slot = slot
    }
    
    #if DEBUG
    private let iphone7Device: Bool = Device.current.isOneOf([.iPhone7, .iPhone7Plus])
    #else
    private let iphone7Device: Bool = Device.current.isOneOf([.iPhone7, .iPhone7Plus])
    #endif
    
    @State private var favourite: Bool = false
    @State private var wishList: Bool = false

    @State private var writingComplete: Bool = false
    @State private var showIdentifyResult: Bool = false
    @State private var scanResult: Amiibo? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                if self.nfcWrite.progress > 0.0 {
                    LinearProgress(self.nfcWrite.progress, color: .blue)
                        .frame(height: 9)
                }
                WebImage(url: self.amiibo.image)
                    .resizable()
                    .indicator(.activity)
                    .transition(.fade)
                    .scaledToFit()
                    .frame(height: 200)
                
                ZStack {
                    BlurView(style: .systemThickMaterial)
                    VStack(spacing: 0) {
                        DetailRow(label: "detail_id", text: self.amiibo.id)
                        DetailRow(label: "detail_name", text: self.amiibo.name)
                        DetailRow(label: "detail_game_series", text: self.amiibo.gameSeries)
                        DetailRow(label: "detail_amiibo_series", text: self.amiibo.amiiboSeries, last: true)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                self.actionButton
            }
            .padding()
        }
        .navigationBarItems(trailing: VStack {
            if self.amiibo.ownedOrWithData {
                Button(action: self.toggleFavourite) {
                    Image(systemName: self.favourite ? "suit.heart.fill" : "suit.heart")
                        .font(.system(size: 20))
                        .foregroundColor(.pink)
                }
                .onAppear(perform: {
                    self.favourite = self.amiibo.favourite
                })
            }
            else {
                EmptyView()
            }
        })
        .navigationBarTitle("\(self.amiibo.name)", displayMode: .inline)
    }
    
    private var actionButton: some View {
        VStack {
            if self.amiibo.ownedOrWithData {
                if self.validateData() {
                    VStack(spacing: 10) {
                        if self.slot == nil {
                            RoundedButton(action: self.restoreData) {
                                Text("restore_data")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        else {
                            RoundedButton(action: self.restoreDataElite) {
                                Text("restore_data_elite")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }

                        if self.writingComplete && UserDefaults.identifyAfterRestore {
                            RoundedButton(color: .gray, action: self.identify) {
                                Text("identify")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .sheet(isPresented: self.$showIdentifyResult) {
                                IdentifyResult(amiibo: self.scanResult, allowSave: false)
                            }
                        }
                    }

                    if self.iphone7Device {
                        Text("restore_iphone7")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .padding()
                            .opacity(0.7)
                    }
                }
                else {
                    Text("backup_invalid")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            else if self.amiibo.data == nil {
                RoundedButton(action: self.toggleWishList) {
                    Text(self.wishList ? "wish_list_remove" : "wish_list_add")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .onAppear(perform: {
                    self.wishList = self.amiibo.wanted
                })
            }
            else {
                EmptyView()
            }
        }
    }
    
    private func validateData() -> Bool {
        return TagUtility.validateTag(self.amiibo.data ?? Data())
    }
    
    private func restoreData() {
        guard self.amiibo.data != nil else { return }
        
        self.nfcWrite.startWritingToTag(self.amiibo.data!, slowWrite: self.iphone7Device) { error in
            guard error == nil else {
                return
            }

            self.writingComplete = true
        }
    }
    
    private func restoreDataElite() {
        guard self.amiibo.data != nil else { return }
        
        self.nfcWrite.startWritingToElite(self.amiibo.data!, slot: self.slot!, slowWrite: self.iphone7Device) { error in
            guard error == nil else {
                return
            }

            self.writingComplete = true

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("n2_elite_restore_done"), object: nil)
            }
        }
    }
    
    private func identify() {
        self.nfcIdentify.scan { data, _, _ in
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
    
    private func toggleFavourite() {
        self.amiibo.favourite.toggle()
        
        AmiiboRepository.shared.write{ db in
            try? self.amiibo.save(db)
            
            self.favourite = self.amiibo.favourite
            
            AmiiboRepository.shared.upload([self.amiibo.characterData.record])
        }
    }
    
    private func toggleWishList() {
        self.amiibo.wanted.toggle()
        
        AmiiboRepository.shared.write{ db in
            try? self.amiibo.save(db)
            
            self.wishList = self.amiibo.wanted
            
            if self.wishList {
                AmiiboRepository.shared.upload([self.amiibo.characterData.record])
            }
            else {
                AmiiboRepository.shared.remove([self.amiibo.characterData.record])
            }
        }
    }
}

struct DetailRow: View {
    let label: LocalizedStringKey
    let text: String
    let last: Bool
    
    init(label: LocalizedStringKey, text: String, last: Bool = false) {
        self.label = label
        self.text = text
        self.last = last
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(self.label)
                    .bold()
                    .foregroundColor(.secondary)
                Spacer()
                Text(self.text)
            }
            .padding(.horizontal)
            .frame(height: 55)
            if !self.last {
                Divider()
            }
        }
    }
}

//struct CharacterDetails_Previews: PreviewProvider {
//    static var previews: some View {
//        CharacterDetails(title: "Test")
//    }
//}
