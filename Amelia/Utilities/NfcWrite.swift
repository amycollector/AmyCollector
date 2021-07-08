//
//  MfcWriteUtility.swift
//  Amii
//
//  Created by Amy Collector on 13/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import CoreNFC

class NfcWrite: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    static let shared: NfcWrite = NfcWrite()
    private var totalPages: Float = Float(Ntag215Pages.TOTAL)
    private var slowWrite: Bool = false
    private var writeMode: NfcWriteMode = .ntag
    private var slot: UInt8 = 0
    
    @Published private(set) var progress: Float = 0.0
    
    var lastPageWritten: UInt8 = 0 {
        willSet(value) {
            self.progress = Float(value) / totalPages
        }
    }

    private var rawData: Data = Data()
    private var action: ((Error?) -> Void)? = nil
    
    func startWritingToTag(_ tagData: Data, slowWrite: Bool, completion: @escaping (Error?) -> Void) {
        self.rawData = tagData
        self.action = completion
        self.slowWrite = slowWrite
        self.writeMode = .ntag
        self.slot = 0
        
        self.writeKeyIfRequired()
        
        if let session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: nil) {
            session.alertMessage = NSLocalizedString("nfc_hold_near_ntag", comment: "")
            session.begin()
        }
    }
    
    func startWritingToElite(_ tagData: Data, slot: UInt8, slowWrite: Bool, completion: @escaping (Error?) -> Void) {
        self.rawData = tagData
        self.action = completion
        self.slowWrite = slowWrite
        self.writeMode = .elite
        self.slot = slot
        
        self.writeKeyIfRequired()
        
        if let session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: nil) {
            session.alertMessage = NSLocalizedString("nfc_hold_near_elite", comment: "")
            session.begin()
        }
    }
    
    func starWritingToPowerTag(_ tagData: Data, slowWrite: Bool, completion: @escaping (Error?) -> Void) {
        self.rawData = tagData
        self.action = completion
        self.slowWrite = slowWrite
        self.writeMode = .powertag
        self.slot = 0
        
        self.writeKeyIfRequired()
        
        if let session = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: nil) {
            session.alertMessage = NSLocalizedString("nfc_hold_near_ptag", comment: "")
            session.begin()
        }
    }
    
    func writeKeyIfRequired() {
        let directory = FileManager.userDirectoryUrl
        let filePath = directory.appendingPathComponent("key_retail")
            .appendingPathExtension("bin")
        
        if (try? filePath.checkResourceIsReachable()) ?? false {
            return
        }
        
        let keyString = "HRZLN1typVcouR1ktqPCBXVuZml4ZWQgaW5mb3MAAA7bS54/RSePOX7/m0+5kwAABEkX3Ha0lkDW+Dk5lg+u1O85L6qyFCiqIftU5UUFR2Z/dS0oc6IAF/74XAV1kEttbG9ja2VkIHNlY3JldAAAEP3IoHaUuJ5MR9N96M5cdMEESRfcdrSWQNb4OTmWD67U7zkvqrIUKKoh+1TlRQVHZg=="
        
        let keyData = Data(base64Encoded: keyString)!
        try? keyData.write(to: filePath)
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.lastPageWritten = 0
        }

        if ![200, 201].contains((error as CoreNFC.NSError).code) {
            DispatchQueue.main.async {
                self.action?(error)
            }
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        DispatchQueue.main.async {
            self.lastPageWritten = 0
        }
        
        if tags.count > 1 {
            session.invalidate(errorMessage: NSLocalizedString("nfc_multiple_found_ntag", comment: ""))
            self.action?(NSError(domain: "app.amycollector.Amii", code: 0, userInfo: [NSLocalizedDescriptionKey: "nfc_multiple_found_ntag"]))
            
            return;
        }
        
        session.connect(to: tags.first!) { error in
            if error != nil {
                DispatchQueue.main.async {
                    self.action?(error)
                }

                session.invalidate(errorMessage: NSLocalizedString("nfc_could_not_connect", comment: ""))

                return
            }
            
            if case let NFCTag.miFare(tag) = tags.first! {
                self.startWritingData(tag, session: session)
            }
            else {
                session.invalidate(errorMessage: NSLocalizedString("nfc_not_valid_ntag", comment: ""))
                
                DispatchQueue.main.async {
                    self.action?(NSError(domain: "app.amycollector.Amii", code: 0, userInfo: [NSLocalizedDescriptionKey: "nfc_not_valid_ntag"]))
                }
            }
        }
    }
    
    private func startWritingData(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {
        let read = Data([MifareCommands.READ, 0])
        
        tag.sendMiFareCommand(commandPacket: read) {(tagData, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.action?(error)
                }
                
                session.invalidate(errorMessage: NSLocalizedString("nfc_could_not_send_command_ntag", comment: ""))
                
                return
            }
            
            guard tagData.count == 16 else {
                DispatchQueue.main.async {
                    self.action?(NSError(domain: "app.amycollector.Amii", code: 0, userInfo: [NSLocalizedDescriptionKey: "nfc_could_not_read_uid_ntag"]))
                }
                
                session.invalidate(errorMessage: NSLocalizedString("nfc_could_not_read_uid_ntag", comment: ""))
                
                return
            }
            
            let directory = FileManager.userDirectoryUrl
            let filePath = directory.appendingPathComponent("key_retail")
                .appendingPathExtension("bin")
            
            if !FileManager.default.fileExists(atPath: filePath.path) {
                session.invalidate(errorMessage: NSLocalizedString("nfc_key_not_found", comment: ""))

                return
            }
            
            let amiitool = Amiitool(filePath.path)
            
            guard self.writeMode == .ntag else {
//                let uuid = TagUtility.geenrateUid()
//                let ntagId = uuid.subdata(in: 0..<3) + uuid.subdata(in: 4..<8)
//                let password = TagUtility.keygen(ntagId)!
//
//                print(ntagId.hexDescription)
//                print(password.hexDescription)
//
//                var decrypted = amiitool.decrypt(self.rawData)
//
//                decrypted.replaceSubrange(0..<9, with: uuid)
//                decrypted.replaceSubrange(468..<476, with: uuid.subdata(in: 0..<8))
//                decrypted[0] = uuid[8]
//
//                self.rawData = amiitool.encrypt(decrypted)
                
                self.n2WriteActiveSlot(tag, session: session)
                
                return
            }
            
            let cc = tagData.subdata(in: 12..<16)
            let size = cc[2]
            
            if size == 0x3E {
                // This is for empty NTAG215
                var decrypted = amiitool.decrypt(self.rawData)
                decrypted.replaceSubrange(468..<476, with: tagData.subdata(in: 0..<8))

                let encrypted = amiitool.encrypt(decrypted)

                self.writeRawDataToTag(tag, rawData: encrypted) { () in
                    session.invalidate()
                    self.action?(nil)
                }

                return
            }
            
            DispatchQueue.main.async {
                self.action?(NSError(domain: "app.amycollector.Amii", code: 0, userInfo: [NSLocalizedDescriptionKey: "nfc_not_empty_ntag"]))
            }

            session.invalidate(errorMessage: NSLocalizedString("nfc_not_empty_ntag", comment: ""))
        }
    }
    
    private func n2WriteActiveSlot(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {
        tag.sendMiFareCommand(commandPacket: Data([MifareCommands.ELITE_ACTIVATE_BANK, self.slot])) { _, activateError in
            if activateError != nil {
                self.action?(activateError)
                
                session.invalidate(errorMessage: activateError!.localizedDescription)
                
                return
            }

            tag.sendMiFareCommand(commandPacket: Data([MifareCommands.FAST_READ, 0, 0])) { fastReadData, fastReadError in
                if fastReadError != nil {
                    self.action?(fastReadError)
                    
                    session.invalidate(errorMessage: fastReadError!.localizedDescription)
                    
                    return
                }
                
                tag.sendMiFareCommand(commandPacket: Data([MifareCommands.PWD_AUTH]) + fastReadData) { authData, authError in
                    if authError != nil {
                        self.action?(authError)
                        
                        session.invalidate(errorMessage: authError!.localizedDescription)
                        
                        return
                    }
                    
                    self.writeRawDataToN2(tag, slot: self.slot, rawData: self.rawData, startPage: 0) { error in
                        if error != nil {
                            self.action?(error)
                            
                            session.invalidate(errorMessage: error!.localizedDescription)
                            
                            return
                        }
                        
                        session.invalidate()
                        
                        self.action?(nil)
                    }
                }
            }
        }
    }
    
    private func ptagWrite(_ tag: NFCMiFareTag, session: NFCTagReaderSession) {
    }
    
    private func writeRawDataToN2(_ tag: NFCMiFareTag, slot: UInt8, rawData: Data, startPage: UInt8, completion: @escaping (Error?) -> Void) {
        if startPage >= Ntag215Pages.TOTAL {
            completion(nil)
            
            return
        }
        
        var command = Data([MifareCommands.ELITE_WRITE, startPage, slot])
        
        switch startPage {
//            case Ntag215Pages.PASSWORD:
//                let ntagid = rawData.subdata(in: 0..<3) + rawData.subdata(in: 4..<8)
//                command += TagUtility.keygen(ntagid)!
//            case Ntag215Pages.PACK:
//                command += Ntag215Data.PACK
//            case Ntag215Pages.CAPABILITY_CONTAINER:
//                command += Ntag215Data.COMPATIBILITY_CONTAINER
//            case Ntag215Pages.CONFIG0:
//                command += Ntag215Data.CONFIG0
//            case Ntag215Pages.CONFIG1:
//                command += Ntag215Data.CONFIG1
//            case Ntag215Pages.DYNAMIC_LOCK_BITS:
//                command += Ntag215Data.DYNAMIC_LOCK_BITS
//            case Ntag215Pages.STATIC_LOCK_BITS:
//                command += Ntag215Data.STATIC_LOCK_BITS
            default:
                command += rawData.page(startPage)
        }
        
        tag.sendMiFareCommand(commandPacket: command) { data, error in
            if error != nil {
                completion(error)

                return
            }

            DispatchQueue.main.async {
                self.lastPageWritten = startPage
            }
            
            self.writeRawDataToN2(tag, slot: slot, rawData: rawData, startPage: startPage + 1, completion: completion)
        }
    }
    
    private func writeRawDataToTag(_ tag: NFCMiFareTag, rawData: Data, completion: @escaping () -> Void) {
        self.writeUserPages(tag, startPage: Ntag215Pages.USER_MEMORY_FIRST, endPage: Ntag215Pages.USER_MEMORY_LAST, data: rawData) { () in
            let password = TagUtility.keygen(tag.identifier)!
            
            print("UID LENGTH: \(tag.identifier.count)")
            print("UID: \(tag.identifier.hexDescription)")
            print("PASSWORD: \(password.hexDescription)")

            #if DEBUG
            completion()
            #else
            self.writePage(tag, page: Ntag215Pages.PASSWORD, data: password) {
                self.writePage(tag, page: Ntag215Pages.PACK, data: Ntag215Data.PACK) {
                    self.writePage(tag, page: Ntag215Pages.CAPABILITY_CONTAINER, data: Ntag215Data.COMPATIBILITY_CONTAINER) {
                        self.writePage(tag, page: Ntag215Pages.CONFIG0, data: Ntag215Data.CONFIG0) {
                            self.writePage(tag, page: Ntag215Pages.CONFIG1, data: Ntag215Data.CONFIG1) {
                                self.writePage(tag, page: Ntag215Pages.DYNAMIC_LOCK_BITS, data: Ntag215Data.DYNAMIC_LOCK_BITS) {
                                    self.writePage(tag, page: Ntag215Pages.STATIC_LOCK_BITS, data: Ntag215Data.STATIC_LOCK_BITS) {
                                        completion()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            #endif
        }
    }
    
    private func writeUserPages(_ tag: NFCMiFareTag, startPage: UInt8, endPage: UInt8, data: Data, completion: @escaping () -> Void) {
        if startPage > endPage {
            completion()

            return
        }

        let page = data.page(startPage)
        self.writePage(tag, page: startPage, data: page) {
            self.writeUserPages(tag, startPage: startPage + 1, endPage: endPage, data: data) { () in
                completion()
            }
        }
    }
    
    private func writePage(_ tag: NFCMiFareTag, page: UInt8, data: Data, completion: @escaping () -> Void) {
        let write = Data([MifareCommands.WRITE, page]) + data

        tag.sendMiFareCommand(commandPacket: write) { (_, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.action?(error)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                self.lastPageWritten = page
            }
            
            if !self.slowWrite {
                completion()
            }
            else {
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05) {
                    completion()
                }
            }
        }
    }
}

enum NfcWriteMode {
    case ntag
    case elite
    case powertag
}
