//
//  BankManagement.swift
//  Amy
//
//  Created by Amy Collector on 08/08/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI
import GRDB

struct BankManagement: View {
    @ObservedObject var nfc: N2EliteManager = N2EliteManager()
    
    @State var amiibos: [Amiibo] = [Amiibo]()
    @State var showActionSheet: Bool = false
    @State var showRestoreSheet: Bool = false
    @State var showSettingsSheet: Bool = false
    
    @State private var currentSlot: UInt8 = 0
    @State private var actionPerformText: LocalizedStringKey = "slot_perform_action 0"
    
    @State private var requiresUpdate: Bool = false

    var body: some View {
        ScrollView {
            if self.amiibos.isEmpty {
                self.emptySection
            }
            else {
                self.slotsSection
            }
        }
        .actionSheet(isPresented: self.$showActionSheet) {
            ActionSheet(title: Text(self.actionPerformText), message: nil, buttons: self.actionButtons())
        }
        .sheet(isPresented: self.$showRestoreSheet) {
            SlotRestore(slot: self.currentSlot)
                .onDisappear {
                    if self.requiresUpdate {
                        self.scanN2Elite()
                        self.requiresUpdate = false
                    }
                }
        }
        .navigationBarItems(trailing: VStack {
            if self.amiibos.isEmpty {
                EmptyView()
            }
            else {
                Button(action: { self.showSettingsSheet = true }) {
                    Image(systemName: "gear")
                }
                .sheet(isPresented: self.$showSettingsSheet) {
                    EliteSettings(availableSlots: self.nfc.eliteVersion![1])
                        .onDisappear {
                            if self.requiresUpdate {
                                self.scanN2Elite()
                                self.requiresUpdate = false
                            }
                        }
                }
            }
        })
        .navigationBarTitle("n2_elite", displayMode: .inline)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("n2_elite_slots"))) { _ in
            self.amiibos.removeAll()
            self.fetchAmiibos()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("n2_elite_restore_done"))) { _ in
            self.requiresUpdate = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            self.amiibos.removeAll()
        }
    }
    
    var emptySection: some View {
        VStack(spacing: 30) {
            EmptyListMessage(message: "empty_n2_bank") {
                Image(systemName: "square.grid.3x2")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            RoundedButton(action: self.scanN2Elite) {
                Text("slots_read")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .padding()
    }
    
    var slotsSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("slots_available")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(self.nfc.eliteVersion![1])/200")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
            }

            HStack {
                Text("slot_active")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(Int(self.nfc.eliteVersion![0]) + 1)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.gray)
            
            ZStack {
                BlurView(style: .systemThickMaterial)
                VStack(spacing: 0) {
                    ForEach(0..<self.amiibos.count, id: \.self) { i in
                        Button(action: { self.slotAction(i) }) {
                            CharacterSlot(amiibo: self.amiibos[i], slot: i + 1, active: Int(self.nfc.eliteVersion![0]) == i, total: self.amiibos.count)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.top, 5)
        }
        .padding(.top)
        .padding(.horizontal)
    }
    
    func actionButtons() -> [ActionSheet.Button] {
        var actions: [ActionSheet.Button] = [ActionSheet.Button]()
        
        actions.append(.default(Text("restore_data"), action: { self.showRestoreSheet = true }))
        
        if self.nfc.eliteVersion![0] != self.currentSlot {
            actions.append(.default(Text("slot_set_active"), action: { self.nfc.performAction(.setActiveSlot, on: self.currentSlot){ _ in} }))
        }
        
        if self.amiibos[Int(self.currentSlot)].data != nil {
            actions.append(.destructive(Text("slot_erase"), action: { self.nfc.performAction(.eraseSlotData, on: self.currentSlot) { _ in} }))
        }
        
        actions.append(.cancel())
        
        return actions
    }
    
    private func slotAction(_ slot: Int) {
        self.actionPerformText = "slot_perform_action \(String(slot + 1))"
        self.currentSlot = UInt8(slot)
        self.showActionSheet = true
    }
    
    private func scanN2Elite() {
        self.nfc.performAction(.getAvailableSlots) { _ in }
    }
    
    private func fetchAmiibos() {
        let empty = Amiibo(id: "ffffffffffffffff", name: "Empty", amiiboSeries: "None", gameSeries: "None", type: .figure, image: URL(string: "https://placeholt.it/100x140")!, data: nil)
        
        var amiibos = [Amiibo]()
        
        self.nfc.slots.forEach { id in
            guard id != "ffffffffffffffff" else {
                amiibos.append(empty)

                return
            }
            
            AmiiboRepository.shared.read { db in
                let char = try? Amiibo.filter(Column("id") == id).fetchOne(db)
                
                guard char != nil else {
                    amiibos.append(empty)

                    return
                }
                
                amiibos.append(char!)
            }
        }
        
        self.amiibos = amiibos
    }
}

fileprivate struct CharacterSlot: View {
    let amiibo: Amiibo
    let slot: Int
    let active: Bool
    let total: Int
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 3) {
                if self.amiibo.data == nil {
                        HStack {
                            Image(systemName: "person.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20)
                        }
                        .frame(width: 50, height: 60)
                        .padding(.vertical, 3)
                        .foregroundColor(.primary)
                        .opacity(0.5)
                }
                else {
                    WebImage(url: self.amiibo.image)
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 60)
                        .padding(.vertical, 3)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text("\(self.slot): \(self.amiibo.name)")
                            .bold()
                    }
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12)
                        Text("\(self.amiibo.gameSeries)")
                    }
                    .font(.caption)
                    .opacity(0.7)
                    HStack {
                        Image(systemName: "person.2.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12)
                        Text("\(self.amiibo.amiiboSeries)")
                    }
                    .font(.caption)
                    .opacity(0.7)
                }
                .foregroundColor(.primary)
                .padding(.vertical, 3)
                Spacer()
                if self.active {
                    VStack(spacing: 0) {
                        Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                                .padding(.trailing, 6)
                        Spacer()
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            if self.slot != self.total {
                Divider()
            }
        }
    }
}

struct BankManagement_Previews: PreviewProvider {
    static var previews: some View {
        BankManagement()
    }
}
