//
//  Array+Extensions.swift
//  Amy
//
//  Created by Amy Collector on 09/08/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
