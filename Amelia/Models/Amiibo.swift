//
//  Amiibo.swift
//  Amelia
//
//  Created by Amy Collector on 11/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import GRDB

class Amiibo: Record {
    var id: String
    var name: String
    var amiiboSeries: String
    var gameSeries: String
    var type: AmiiboType
    var image: URL
    var data: Data?
    var notes: String = ""
    var favourite: Bool = false
    var owned: Bool = false
    var wanted: Bool = false
    
    init(id: String, name: String, amiiboSeries: String, gameSeries: String, type: AmiiboType, image: URL, data: Data?) {
        self.id = id
        self.name = name
        self.amiiboSeries = amiiboSeries
        self.gameSeries = gameSeries
        self.type = type
        self.image = image
        self.data = data
        
        super.init()
    }
    
    required init(row: Row) {
        self.id = row[Columns.id]
        self.name = row[Columns.name]
        self.amiiboSeries = row[Columns.amiiboSeries]
        self.gameSeries = row[Columns.gameSeries]
        self.type = row[Columns.type]
        self.image = row[Columns.image]
        self.data = row[Columns.data]
        self.notes = row[Columns.notes]
        self.favourite = row[Columns.favourite]
        self.owned = row[Columns.owned]
        self.wanted = row[Columns.wanted]
        
        super.init(row: row)
    }
    
    override func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = self.id
        container[Columns.name] = self.name
        container[Columns.amiiboSeries] = self.amiiboSeries
        container[Columns.gameSeries] = self.gameSeries
        container[Columns.type] = self.type
        container[Columns.image] = self.image
        container[Columns.data] = self.data
        container[Columns.notes] = self.notes
        container[Columns.favourite] = self.favourite
        container[Columns.owned] = self.owned
        container[Columns.wanted] = self.wanted
    }
    
    // The table name
    override class var databaseTableName: String { "amiibov2" }
    
    // The table columns
    enum Columns: String, ColumnExpression {
        case id, name, amiiboSeries, gameSeries, type, image, data, notes, favourite, owned, wanted
    }
}

extension Amiibo {
    var ownedOrWithData: Bool {
        return (self.data != nil && self.data!.count > 500) || self.owned
    }
    
    var characterData: CharacterData {
        return CharacterData(id: self.id, favourite: self.favourite, wanted: self.wanted, data: self.data)
    }
    
    func clear() {
        self.data = nil
        self.owned = false
        self.wanted = false
        self.favourite = false
        self.notes = ""
    }
}

enum AmiiboType: String, DatabaseValueConvertible, Codable {
    case card
    case figure
    case yarn
}
