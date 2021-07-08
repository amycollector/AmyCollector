//
//  AmiiboData.swift
//  Amelia
//
//  Created by Amy Collector on 11/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation

struct AmiiboData: Codable {
    var amiiboSeries: String
    var gameSeries: String
    var head: String
    var tail: String
    var name: String
    var image: URL
    var type: AmiiboType
    
    enum CodingKeys: String, CodingKey {
        case amiiboSeries
        case gameSeries
        case head
        case tail
        case name
        case image
        case type
    }
}
