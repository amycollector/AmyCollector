//
//  File.swift
//  Amii
//
//  Created by Amy Collector on 13/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import CoreNFC

class NfcIndentify: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    private var action: ((Data?, [String: String]?, Error?) -> Void)? = nil
    
    func scan(_ completion: @escaping (Data?, [String: String]?, Error?) -> Void) {
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
                self.action?(nil, nil, error)
            }
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        if tags.count > 1 {
            session.invalidate(errorMessage: NSLocalizedString("nfc_multiple_found", comment: ""))
            self.action?(nil, nil, NSError(domain: "app.amycollector.Amii", code: 0))
            
            return
        }
        
        session.connect(to: tags.first!) { (error: Error?) in
            if (error != nil) {

                DispatchQueue.main.async {
                    self.action?(nil, nil, error)
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
        let read = Data([MifareCommands.READ, 0])
            
        tag.sendMiFareCommand(commandPacket: read) { (data, error) in
            if (error != nil) {

                DispatchQueue.main.async {
                    self.action?(nil, nil, error)
                }
                
                session.invalidate(errorMessage: NSLocalizedString("nfc_not_valid", comment: ""))
                
                return
            }
            
            guard data.count == 16 else {
                DispatchQueue.main.async {
                    self.action?(nil, nil, NSError(domain: "app.amycollector.Amii", code: 0, userInfo: [NSLocalizedDescriptionKey: "nfc_could_not_read_uid"]))
                }
                
                session.invalidate(errorMessage: NSLocalizedString("nfc_could_not_read_uid", comment: ""))
                
                return
            }
            
            self.dumpTagData(tag) { data in
                DispatchQueue.main.async {
                    session.invalidate()
                    
                    self.action?(data, ["head": data.head, "tail": data.tail], nil)
                }
                
                return
            }
        }
    }
    
    private func dumpTagData(_ tag: NFCMiFareTag, completion: @escaping (Data) -> Void) {
        self.readAllPages(tag, startPage: 0, completion: completion)
    }
    
    private func readAllPages(_ tag: NFCMiFareTag, startPage: UInt8, completion: @escaping (Data) -> Void) {
        if (startPage >= Ntag215Pages.TOTAL) {
            completion(Data())

            return
        }

        let read = Data([MifareCommands.READ, startPage])
        tag.sendMiFareCommand(commandPacket: read) { (data, error) in
            if (error != nil) {
                self.action?(nil, nil, error)
                
                return
            }
            
            self.readAllPages(tag, startPage: startPage + 4) { contents in
                completion(data + contents)
            }
        }
    }
}
