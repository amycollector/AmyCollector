//
//  IdentifyResult.swift
//  Amelia
//
//  Created by Amy Collector on 13/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct IdentifyResult: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: LocalizedStringKey = "not_found_amiibo"

    let amiibo: Amiibo?
    var allowSave: Bool = true
    let autoSave: Bool = UserDefaults.autoSave

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    if self.amiibo != nil {
                        self.amiiboDetails
                    }
                    else {
                        self.noResulView
                    }
                }
                .onAppear {
                    guard self.amiibo != nil else { return }
                    self.title = "\(self.amiibo!.name)"
                    
                    guard self.autoSave else { return }
                    self.saveScannedAmiibo(dismiss: false)
                }
                .padding()
            }
            .navigationBarItems(trailing: VStack {
                Button("dismiss") {
                    self.dismiss()
                }
            })
            .navigationBarTitle(self.title, displayMode: .inline)
        }
    }
    
    private var amiiboDetails: some View {
        VStack(spacing: 30) {
            WebImage(url: self.amiibo!.image)
                .resizable()
                .indicator(.activity)
                .transition(.fade)
                .scaledToFit()
                .frame(height: 200)
            
            ZStack {
                BlurView(style: .systemThickMaterial)
                VStack(spacing: 0) {
                    DetailRow(label: "detail_id", text: self.amiibo!.id)
                    DetailRow(label: "detail_name", text: self.amiibo!.name)
                    DetailRow(label: "detail_game_series", text: self.amiibo!.gameSeries)
                    DetailRow(label: "detail_amiibo_series", text: self.amiibo!.amiiboSeries, last: true)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            VStack(spacing: 10) {
                if !self.autoSave && self.allowSave {
                    RoundedButton(action: { self.saveScannedAmiibo() }){
                        Text("backup_dismiss")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    }
                }

                RoundedButton(color: .gray, action: self.dismiss){
                    Text("dismiss")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private var noResulView: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .resizable()
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .foregroundColor(.red)
                .opacity(0.8)
                .padding(.bottom, 20)
                .padding(.top, 5)
                .padding(.leading, -20)
            Text("not_amiibo")
                .multilineTextAlignment(.center)
            RoundedButton(action: self.dismiss){
                Text("dismiss")
                .fontWeight(.semibold)
                .foregroundColor(.white)
            }
        }
    }
    
    private func dismiss() {
        self.presentationMode.wrappedValue.dismiss()
    }
    
    private func saveScannedAmiibo(dismiss: Bool = true) {
        guard self.amiibo != nil else { return }
        
        AmiiboRepository.shared.write { db in
            self.amiibo!.owned = true
            self.amiibo!.wanted = false
            
            try? self.amiibo!.save(db)
            
            AmiiboRepository.shared.upload([self.amiibo!.characterData.record])
        }
        
        if dismiss {
            self.dismiss()
        }
    }
}

struct IdentifyResult_Previews: PreviewProvider {
    static var previews: some View {
        IdentifyResult(amiibo: nil)
    }
}
