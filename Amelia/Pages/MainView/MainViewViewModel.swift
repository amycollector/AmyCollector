//
//  MainViewViewModel.swift
//  Amelia
//
//  Created by Amy Collector on 11/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import GRDB

final class MainViewViewModel: ObservableObject {
    @Published private(set) var totalItems: Int = 0
    @Published private(set) var totlaOwned: Int = 0

    @Published private(set) var favourites: [Amiibo] = [Amiibo]()
    @Published private(set) var ownedGrouped: [GameSeries] = [GameSeries]()
    @Published private(set) var wishListGrouped: [GameSeries] = [GameSeries]()
    
    func fetchFavourites() {
        AmiiboRepository.shared.read { db in
            let favouriteAmiibos = try? Amiibo
                .filter(Column("data") != nil || Column("owned") == true)
                .filter(Column("favourite") == true)
                .order([Column("gameSeries").asc, Column("name").asc])
                .fetchAll(db)
            
            self.favourites = favouriteAmiibos ?? [Amiibo]()
        }
    }
    
    func fetchOwned() {
        AmiiboRepository.shared.read { db in
            let groups = try? Row.fetchAll(db, sql: "SELECT gameSeries, COUNT(*) FROM amiibov2 WHERE data NOT NULL OR owned = 1 GROUP BY gameSeries ORDER BY gameSeries ASC")
            
            guard groups != nil else { return }
            
            var totalOwned = 0
            
            self.ownedGrouped = groups!.map({ row in
                totalOwned += row["count(*)"] as Int

                return GameSeries(name: row["gameSeries"], count: row["count(*)"])
            })
            
            self.totlaOwned = totalOwned
        }
    }
    
    func fetchWishList() {
        AmiiboRepository.shared.read { db in
            let groups = try? Row.fetchAll(db, sql: "SELECT gameSeries, COUNT(*) FROM amiibov2 WHERE wanted = 1 GROUP BY gameSeries ORDER BY gameSeries ASC")
            
            guard groups != nil else { return }
            
            self.wishListGrouped = groups!.map({ row in
                return GameSeries(name: row["gameSeries"], count: row["count(*)"])
            })
        }
    }
    
    func performReadMeWrite() {
        let directory = FileManager.userDirectoryUrl
        
        let filePath = directory.appendingPathComponent("README")
            .appendingPathExtension("txt")
        
        let readmeExists = try? filePath.checkResourceIsReachable()
        if !(readmeExists ?? false) {
            let readme = "Do not remove this file. This allows you to access the folder in the Files app."
            
            do {
                try readme.write(to: filePath, atomically: true, encoding: .utf8)
            }
            catch {
                print(error)
            }
        }
    }
    
    func performDataSeeding() {
        let seeded = UserDefaults.dataMigrated
        
        guard !seeded else {
            AmiiboRepository.shared.read { db in
                let count = try? Int.fetchOne(db, sql: "SELECT COUNT(*) FROM amiibov2")
                
                self.totalItems = count != nil ? count! - 1 : 0
            }
            
            return
        }
        
        let path = Bundle.main.path(forResource: "amiiboapi", ofType: "json")!
        let jsonData = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let decoder = JSONDecoder()
        let rawData = try! decoder.decode([AmiiboData].self, from: jsonData)
        
        #if targetEnvironment(simulator)
        let owned = ["Ankha", "Broccolo", "Bruce", "Katie", "Kidd", "Lolly", "Marina", "Nat", "Lucas"]
        let favourite = ["Ankha", "Bruce", "Marina", "Lucas"]
        let wanted = ["Diana", "Detective Pikachu", "Pichu", "Lucario", "Greninja", "Mewtwo", "Incineroar", "Squirtle", "Zelda", "Link (Archer)"]
        #endif
        
        let seedData = rawData.map({ raw -> Amiibo in
            var data: Amiibo
            
            #if targetEnvironment(simulator)
            data = Amiibo(id: "\(raw.head)\(raw.tail)", name: raw.name, amiiboSeries: raw.amiiboSeries, gameSeries: raw.gameSeries, type: raw.type, image: raw.image, data: owned.contains(raw.name) ? Data(count: 544) : nil)
            data.favourite = favourite.contains(raw.name)
            data.wanted = wanted.contains(raw.name)
            #else
            data = Amiibo(id: "\(raw.head)\(raw.tail)", name: raw.name, amiiboSeries: raw.amiiboSeries, gameSeries: raw.gameSeries, type: raw.type, image: raw.image, data: nil)
            #endif
            
            return data
        })
        
        AmiiboRepository.shared.write { db in
            seedData.forEach { item in
                try! item.save(db)
            }
        }
        
        self.totalItems = seedData.count - 1
        
        UserDefaults.dataMigrated = true
    }
    
    func performDataImport() {
        let filesToImport = FileManager.importFileUrls
        
        guard !filesToImport.isEmpty else { return }
        
        var filesDictionary: [String: Data] = [String: Data]()
        
        filesToImport.forEach { url in
            let data = try? Data(contentsOf: url)
            
            guard data != nil else { return }
            guard TagUtility.validateTag(data!) else { return }
            
            return filesDictionary[data!.id] = data!
        }
        
        AmiiboRepository.shared.write { db in
            let characterIds = Array(filesDictionary.keys)
            let characters = try! Amiibo.filter(characterIds.contains(Column("id"))).fetchAll(db)

            var toUpload: [CharacterData] = [CharacterData]()

            characters.forEach { character in
                character.data = filesDictionary[character.id]
                character.owned = true
                toUpload.append(character.characterData)

                try? character.save(db)
            }
            
            AmiiboRepository.shared.upload(toUpload.map({ d in return d.record}))
            
            filesToImport.forEach { path in
                try? FileManager.default.removeItem(at: path)
            }
        }
    }
    
    func performInitialSync() {
        if !UserDefaults.initialCloudSync {
            
            UserDefaults.initialCloudSync = true
        }
    }
}
