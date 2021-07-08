//
//  AboutPage.swift
//  Amii
//
//  Created by Amy Collector on 15/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI
import SDWebImage
import GRDB

struct About: View {
    @State var showConfirm: Bool = false
    @State var message: String = ""
    @State var cancelButtonText: String = ""
    @State var action: (() -> Void) = {}
    @State var version: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("about_acknowledgements")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    SettingsSection {
                        SettingsRowText<EmptyView>(text: "AmiiboAPI")
                        SettingsRowText<EmptyView>(text: "Amiitool")
                        SettingsRowText<EmptyView>(text: "CattleGrid", last: true)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("about_swift_libs")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    SettingsSection {
                        SettingsRowText<EmptyView>(text: "DeviceKit")
                        SettingsRowText<EmptyView>(text: "GRDB")
                        SettingsRowText<EmptyView>(text: "SDWebImageSwiftUI", last: true)
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("about_reset")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    SettingsSection {
                        Button(action: self.resetImageConfirm) {
                            SettingsRowText<EmptyView>(text: "about_reset_image_cache")
                        }
                        Button(action: self.resetDataConfirm) {
                            SettingsRowText<EmptyView>(text: "about_reset_data", last: true)
                        }
                    }
                    .foregroundColor(.red)
                }
                SettingsSection {
                    SettingsRowText<EmptyView>(text: "Version \(self.version)")
                        .onAppear(perform: {
                            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                self.version = version

                                if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                                    self.version = "\(version)-\(build)"
                                }
                            }
                        })
                    SettingsRowText<EmptyView>(text: "Crafted with ❤️ in Manchester, UK", last: true)
                }
            }
            .padding()
        }
        .alert(isPresented: self.$showConfirm) {
            self.alert
        }
        .navigationBarTitle("settings_about", displayMode: .inline)
    }
    
    private var alert: Alert {
        Alert(title: Text("about_reset"), message: Text("\(self.message)"), primaryButton: .cancel(Text("about_reset_cancel")), secondaryButton: .destructive(Text("\(self.cancelButtonText)"), action: self.action))
    }
    
    private func resetImageConfirm() {
        self.action = self.resetCache
        self.message = NSLocalizedString("about_reset_image_cache_question", comment: "")
        self.cancelButtonText = NSLocalizedString("about_reset_image_cache_yes", comment: "")
        self.showConfirm = true
    }
    
    private func resetDataConfirm() {
        self.action = self.resetData
        self.message = NSLocalizedString("about_reset_data_question", comment: "")
        self.cancelButtonText = NSLocalizedString("about_reset_data_yes", comment: "")
        self.showConfirm = true
    }
    
    private func resetCache() {
        SDImageCache.shared.clear(with: .all)
    }
    
    private func resetData() {
        AmiiboRepository.shared.write { db in
            let characters = try! Amiibo
                    .filter(Column("data") != nil || Column("owned") == true || Column("favourite") == true || Column("wanted") == true)
                .fetchAll(db)
            
            guard !characters.isEmpty else { return }
            
            var toDelete: [CharacterData] = [CharacterData]()
            
            characters.forEach { character in
                character.clear()
                
                try? character.save(db)

                toDelete.append(character.characterData)
            }
            
            AmiiboRepository.shared.remove(toDelete.map{ r in return r.record})
        }
    }
}

struct About_Previews: PreviewProvider {
    static var previews: some View {
        About()
    }
}
