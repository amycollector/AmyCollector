//
//  Settings.swift
//  Amelia
//
//  Created by Amy Collector on 10/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI
import MessageUI

struct Settings: View {
    @ObservedObject private var viewModel: SettingsViewModel = SettingsViewModel()

    @State private(set) var lastUpdated: String = UserDefaults.lastUpdated
    @State private(set) var showWhatsNew: Bool = false
    @State private(set) var showHelp: Bool = false
    @State private(set) var showEmail: Bool = false
    @State private(set) var result: Result<MFMailComposeResult, Error>? = nil
    
    private var autoSave: Binding<Bool> = Binding<Bool>(get: {
        return UserDefaults.autoSave
    }, set: {
        UserDefaults.autoSave = $0
    })
    
    private var identifyAfter: Binding<Bool> = Binding<Bool>(get: {
        return UserDefaults.identifyAfterRestore
    }, set: {
        UserDefaults.identifyAfterRestore = $0
    })
    
    private var n2Elite: Binding<Bool> = Binding<Bool>(get: {
        return UserDefaults.n2EliteSupport
    }, set: {
        UserDefaults.n2EliteSupport = $0
    })
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                SettingsSection {
                    Button(action: { self.showWhatsNew = true }) {
                        SettingsRow<EmptyView>(imageName: "envelope.fill", text: "settings_whats_new", tint: .red)
                    }
                    .sheet(isPresented: self.$showWhatsNew ) {
                        WhatsNew()
                    }

                    Button(action: { self.showHelp = true}) {
                        SettingsRow<EmptyView>(imageName: "quote.bubble.fill", text: "settings_need_help", tint: .purple)
                    }
                    .sheet(isPresented: self.$showHelp ) {
                        Help()
                    }

                    Button(action: { self.showEmail = true }) {
                        SettingsRow<EmptyView>(imageName: "paperplane.fill", text: "settings_send_feedback", tint: .yellow, last: true)
                    }
                    .disabled(!MFMailComposeViewController.canSendMail())
                    .sheet(isPresented: self.$showEmail) {
                        MailView(result: self.$result)
                    }
                }
                
                SettingsSection {
                    NavigationLink(destination: About()) {
                        SettingsRow(imageName: "exclamationmark.circle.fill", text: "settings_about", tint: .blue) {
                            ChevronRight()
                        }
                    }
                    NavigationLink(destination: PrivacyPolicy()) {
                        SettingsRow(imageName: "lock.fill", text: "settings_privacy_policy", tint: .gray, last: true) {
                            ChevronRight()
                        }
                    }
                }
                .foregroundColor(.primary)
                
                VStack(alignment: .leading,spacing: 10) {
                    Text("settings_options")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    SettingsSection {
                        SettingsRow<Toggle<Text>>(imageName: "arrow.down.doc.fill", text: "", tint: .green) {
                            Toggle(isOn: self.autoSave){ Text("settings_autosave") }
                        }
                        SettingsRow<Toggle<Text>>(imageName: "doc.text.viewfinder", text: "", tint: .blue) {
                            Toggle(isOn: self.identifyAfter){ Text("settings_identify") }
                        }
                        SettingsRow<Toggle<Text>>(imageName: "square.grid.3x2", text: "", tint: .pink) {
                            Toggle(isOn: self.n2Elite){ Text("settings_elite") }
                        }
                        NavigationLink(destination: CustomIcons()) {
                            SettingsRow(imageName: "paintbrush.fill", text: "settings_custom_icon", tint: .orange, last: true) {
                                ChevronRight()
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("settings_amiibo_data")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    SettingsSection {
                        Button(action: self.checkForUpdates) {
                            SettingsRow<EmptyView>(imageName: "arrow.2.circlepath", text: "settings_check_update", tint: .blue, last: true)
                        }
                    }
                    Text("Last updated: \(self.lastUpdated)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationBarTitle("settings", displayMode: .inline)
    }
    
    private func checkForUpdates() {
        self.viewModel.checkForUpdates() {
            self.lastUpdated = UserDefaults.lastUpdated
        }
    }
}

struct SettingsSection<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            BlurView(style: .systemThickMaterial)
            VStack(spacing: 0) {
                self.content
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct SettingsRow<Content: View>: View {
    let imageName: String
    let text: LocalizedStringKey
    let tint: Color
    let extra: Content?
    let last: Bool
    
    init(imageName: String, text: LocalizedStringKey, tint: Color, last: Bool = false, @ViewBuilder extra: () -> Content? = { nil }) {
        self.imageName = imageName
        self.text = text
        self.tint = tint
        self.extra = extra()
        self.last = last
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    Image(systemName: "app.fill")
                        .resizable()
                        .foregroundColor(self.tint)
                    Image(systemName: self.imageName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .padding(4)
                }
                .frame(width: 28, height: 28)
                if self.text != "" {
                    Text(self.text)
                    Spacer()
                }
                if self.extra != nil {
                    self.extra!
                }
            }
            .padding(.horizontal)
            .frame(height: 55)
            if !self.last {
                Divider()
            }
        }
    }
}

struct SettingsRowText<Content: View>: View {
    let text: LocalizedStringKey
    let extra: Content?
    let last: Bool
    
    init(text: LocalizedStringKey, extra: Content? = nil, last: Bool = false) {
        self.text = text
        self.extra = extra
        self.last = last
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                if self.text != "" {
                    Text(self.text)
                    Spacer()
                }
                if self.extra != nil {
                    self.extra!
                }
            }
            .padding(.horizontal)
            .frame(height: 55)
            if !self.last {
                Divider()
            }
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
