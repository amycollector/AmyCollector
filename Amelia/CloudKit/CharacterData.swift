//
//  CharacterData.swift
//  Amii
//
//  Created by Amy Collector on 01/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import CloudKit

struct CharacterData: Hashable, Codable, Identifiable {
    let id: String
    let favourite: Bool
    let wanted: Bool
    let data: Data?
    
    init(id: String, favourite: Bool, wanted: Bool, data: Data) {
        self.id = id
        self.favourite = favourite
        self.wanted = wanted
        self.data = data
    }
    
    init(id: String, favourite: Bool, wanted: Bool, data: Data? = nil) {
        self.id = id
        self.favourite = favourite
        self.wanted = wanted
        self.data = data
    }
}

extension CKRecord.RecordType {
    static let characterData: String = "CharacterData"
}

extension CharacterData {
    enum RecordKey: String {
        case id
        case favourite
        case wanted
        case data
    }
    
    var recordId: CKRecord.ID {
        CKRecord.ID(recordName: self.id, zoneID: SyncConstants.customZoneId)
    }
    
    var record: CKRecord {
        let r = CKRecord(recordType: .characterData, recordID: self.recordId)
        
        r[.id] = self.id
        r[.favourite] = self.favourite
        r[.wanted] = self.wanted
        r[.data] = self.data
        
        return r
    }
    
    init(record: CKRecord) {
        self.id = record[.id] as! String
        self.favourite = (record[.favourite] as? Bool) ?? false
        self.wanted = (record[.wanted] as? Bool) ?? false
        self.data = record[.data] as? Data
    }
}

extension CharacterData {
    static func resolveConflict(clientRecord: CKRecord, serverRecord: CKRecord) -> CKRecord? {
        guard let clientDate = clientRecord.modificationDate, let serverDate = serverRecord.modificationDate else {
            return clientRecord
        }

        if clientDate > serverDate {
            return clientRecord
        } else {
            return serverRecord
        }
    }
}

fileprivate extension CKRecord {
    subscript(key: CharacterData.RecordKey) -> Any? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue as? CKRecordValue
        }
    }
}

