//
//  AmiiboRepository.swift
//  Amelia
//
//  Created by Amy Collector on 11/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import GRDB
import CloudKit

class AmiiboRepository {
    static let shared: AmiiboRepository = AmiiboRepository()
    
    private let dbPath: URL = FileManager.default
        .urls(for: .libraryDirectory, in: .userDomainMask).first!
        .appendingPathComponent("tags")
        .appendingPathExtension("sqlite")

    private let cloudKit: CloudKitHelper
    
    init() {
        let database = try? DatabaseQueue(path: self.dbPath.absoluteString)
        
        try? database?.write { db in
            try db.create(table: "amiibov2", ifNotExists: true) { table in
                table.primaryKey(["id"])
                table.column("id", .text)
                table.column("name", .text)
                table.column("amiiboSeries", .text)
                table.column("gameSeries", .text)
                table.column("type", .text)
                table.column("image", .blob)
                table.column("data", .blob)
                table.column("notes", .text).defaults(to: "")
                table.column("favourite", .boolean).defaults(to: false)
                table.column("owned", .boolean).defaults(to: false)
                table.column("wanted", .boolean).defaults(to: false)
            }
        }
        
        self.cloudKit = CloudKitHelper.shared
    }
    
    func write(completionHandler: @escaping (Database) -> Void) {
        let database = try? DatabaseQueue(path: self.dbPath.absoluteString)
        try? database?.write { db in
            completionHandler(db)
        }
    }
    
    func read(completionHandler: @escaping (Database) -> Void) {
        let database = try? DatabaseQueue(path: self.dbPath.absoluteString)
        database?.read { db in
            completionHandler(db)
        }
    }
}

extension AmiiboRepository {
    func upload(_ records: [CKRecord]) {
        self.cloudKit.uploadLocalChanges(records)
    }
    
    func remove(_ records: [CKRecord]) {
        self.cloudKit.removeItems(records)
    }
    
    func fetchCloud(completion: @escaping ([CharacterData], [String]) -> Void) {
        self.cloudKit.fetchRemoteChanges{ items,delete,_ in
            let cloudItems = items.map({ (i) -> CharacterData in
                return CharacterData(record: i)
            })
            
            let deleted = delete.map({ (i) -> String in
                return i.recordName
            })
            
            completion(cloudItems, deleted)
        }
    }

    func performSync(upload: Bool = false) {
        AmiiboRepository.shared.fetchCloud { updated, deleted in
            
            let itemsDictionary = updated.reduce(into: [String: CharacterData]()) {
                return $0[$1.id] = $1
            }
            
            AmiiboRepository.shared.write { db in
                if !updated.isEmpty {
                    let characters = try! Amiibo.filter(Array(itemsDictionary.keys).contains(Column("id"))).fetchAll(db)
                    characters.forEach { character in
                        let item = itemsDictionary[character.id]!
                        
                        character.data = item.data
                        character.favourite = item.favourite
                        character.wanted = item.wanted
                        
                        try? character.save(db)
                    }
                }
                
                if !deleted.isEmpty {
                    let toDelete = try! Amiibo.filter(deleted.contains(Column("id"))).fetchAll(db)
                    toDelete.forEach { character in
                        character.clear()
                        
                        try? character.save(db)
                    }
                }
                
                if upload {
                    let toUpload = try! Amiibo
                        .filter((Array(itemsDictionary.keys).contains(Column("id")).negated || deleted.contains(Column("id")))
                            && Column("data") != nil || Column("favourite") == true || Column("wanted") == true)
                        .fetchAll(db)

                    var records: [CKRecord] = [CKRecord]()
                    
                    toUpload.forEach{ character in
                        records.append(character.characterData.record)
                    }
                    
                    AmiiboRepository.shared.upload(records)
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(name: NSNotification.Name("icloud_sync_done"), object: nil)
                }
            }
        }
    }
}
