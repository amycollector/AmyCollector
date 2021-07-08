//
//  File.swift
//  Amii
//
//  Created by Amy Collector on 08/08/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import CoreNFC

class N2EliteManager: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    private var action: ((Error?) -> Void)!
    private var n2EliteAction: N2EliteAction = .getVersion
    
    private(set) var slots: [String] = []
    private(set) var eliteVersion: Data? = nil
    
    func scan(_ n2EliteAction: N2EliteAction, _ completion: @escaping (Error?) -> Void) {
        self.n2EliteAction = n2EliteAction
        self.action = completion
        
        if let session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: nil) {
            session.alertMessage = NSLocalizedString("nfc_hold_near", comment: "")
            session.begin()
        }
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        if (![200, 201].contains((error as CoreNFC.NSError).code)) {
            DispatchQueue.main.async {
                self.action(error)
            }
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if tags.count > 1 {
            session.invalidate(errorMessage: NSLocalizedString("nfc_multiple_found", comment: ""))
            self.action(NSError(domain: "app.amycollector.Amii", code: 0))
            
            return
        }
        
        session.connect(to: tags.first!) { (error: Error?) in
            if (error != nil) {

                DispatchQueue.main.async {
                    self.action(error)
                }
                
                session.invalidate(errorMessage: NSLocalizedString("nfc_could_not_connect", comment: ""))
                
                return
            }
            
            if case let NFCTag.miFare(tag) = tags.first! {
                self.connected(tag, session: session)
            }
        }
    }
    
    private func connected(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {

        let getVersion = Data([MifareCommands.ELITE_GET_VERSION])
        
        tag.sendMiFareCommand(commandPacket: getVersion) { versionData, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.action(error)
                }

                session.invalidate(errorMessage: NSLocalizedString("nfc_not_valid", comment: ""))

                return
            }
            
            

            self.slots.removeAll(keepingCapacity: false)

            self.getAllSlots(tag, slot: 0, maxSlots: versionData[1]) { getSlotsError in
                if getSlotsError != nil {
                    DispatchQueue.main.async {
                        self.action(error)
                    }

                    session.invalidate(errorMessage: NSLocalizedString("nfc_not_valid", comment: ""))

                    return
                }

                DispatchQueue.main.async {
                    self.action(nil)
                }

                session.invalidate()
            }
        }
    }
    
    private func getAllSlots(_ tag: NFCMiFareTag, slot: UInt8, maxSlots: UInt8, completion: @escaping (Error?) -> Void) {
        if slot >= maxSlots {
            completion(nil)
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("n2_elite_slots"), object: nil)
            }
            
            return
        }
        
        tag.sendMiFareCommand(commandPacket: Data([MifareCommands.ELITE_FAST_READ, 21, 22, slot])) { slotData, error in
            if error != nil {
                completion(error)
                
                return
            }
            
            self.slots.append(slotData.hexDescription)
            
            self.getAllSlots(tag, slot: slot + 1, maxSlots: maxSlots, completion: completion)
        }
    }
}

enum N2EliteAction {
    case getVersion
    case getAllBanks
}
