//
//  SlotRestoreViewModel.swift
//  Amy
//
//  Created by Amy Collector on 10/08/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import GRDB

final class SlotRestoreViewModel: NSObject, ObservableObject {
    @Published private(set) var totalItems: Int = 0
    @Published private(set) var totlaOwned: Int = 0

    @Published private(set) var favourites: [Amiibo] = [Amiibo]()
    @Published private(set) var ownedGrouped: [GameSeries] = [GameSeries]()
    
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
    
}
