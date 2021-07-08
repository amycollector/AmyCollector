//
//  SearchAmiibosViewModel.swift
//  Amy
//
//  Created by Amy Collector on 13/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import GRDB

final class SearchAmiibosViewModel: ObservableObject {
    @Published private(set) var amiibos: [Amiibo] = [Amiibo]()

    var searchText: String = ""
    
    func fetchAmiibos(includeOwned: Bool = false) {
        guard self.searchText.trimmingCharacters(in: CharacterSet(charactersIn: " ")) != "" else {
            self.amiibos = [Amiibo]()

            return
        }

        AmiiboRepository.shared.read { db in
            if includeOwned {
                let amiibos = try? Amiibo
                    .filter(Column("name").like("%\(self.searchText)%"))
                    .order([Column("gameSeries").asc, Column("name").asc])
                    .fetchAll(db)
                
                self.amiibos = amiibos ?? [Amiibo]()
                
                return
            }
            
            let amiibos = try? Amiibo
                .filter(Column("data") == nil && Column("owned") == false && Column("wanted") == false)
                .filter(Column("name").like("%\(self.searchText)%"))
                .order([Column("gameSeries").asc, Column("name").asc])
                .fetchAll(db)
            
            self.amiibos = amiibos ?? [Amiibo]()
            print(self.amiibos.count)
        }
    }
}
