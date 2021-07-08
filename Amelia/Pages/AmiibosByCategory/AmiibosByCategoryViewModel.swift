//
//  AmiibosByCategoryViewModel.swift
//  Amelia
//
//  Created by Amy Collector on 12/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import SwiftUI
import GRDB
import UIKit

final class AmiibosByCategoryViewModel: ObservableObject {
    var searchText: String = ""
    @Published private(set) var amiibos: [Amiibo] = [Amiibo]()
    @Published private(set) var emptyListText: LocalizedStringKey = "no_amiibo_list"
    
    func fetchAmiibos(category: String, subCategory: AmiibosByCategory.SubCategory = .owned) {
        AmiiboRepository.shared.read { db in
            if subCategory == .wanted {
                let amiibos = try? Amiibo
                    .filter(Column("name").like("%\(self.searchText)%"))
                    .filter(Column("gameSeries") == category)
                    .filter(Column("wanted") == true)
                    .order([Column("gameSeries").asc, Column("name").asc])
                    .fetchAll(db)
                
                self.amiibos = amiibos ?? [Amiibo]()
                
                self.emptyListText = self.searchText.trimmingCharacters(in: CharacterSet(charactersIn: " ")) != ""
                    ? "no_amiibo_list_search \(self.searchText)"
                    : "no_amiibo_list"
                
                return
            }
            
            let amiibos = try? Amiibo
                .filter(Column("name").like("%\(self.searchText)%"))
                .filter(Column("gameSeries") == category)
                .filter(Column("data") != nil || Column("owned") == true)
                .order([Column("gameSeries").asc, Column("name").asc])
                .fetchAll(db)
            
            self.emptyListText = self.searchText.trimmingCharacters(in: CharacterSet(charactersIn: " ")) != ""
                ? "no_amiibo_list_search \(self.searchText)"
                : "no_amiibo_list"
            
            self.amiibos = amiibos ?? [Amiibo]()
        }
    }
    
    func clearAmiiboData(at: Int) {
        let amiibo = self.amiibos[at]
        amiibo.clear()
        
        AmiiboRepository.shared.write { db in
            try! amiibo.save(db)
            
            AmiiboRepository.shared.remove([amiibo.characterData.record])
        }
    }
}
