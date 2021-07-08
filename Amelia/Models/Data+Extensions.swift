//
//  Data+Extensions.swift
//  Amii
//
//  Created by Amy Collector on 13/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation

extension Data {
    var unsafeBytes: UnsafePointer<UInt8> {
        self.withUnsafeBytes {
            $0
        }
    }
    
    var hexDescription: String {
        return reduce("") {
            $0 + String(format: "%02x", $1)
        }
    }
    
    var id: String {
        let start = Int(TagUtility.PAGE_SIZE) * Int(Ntag215Pages.MODEL_HEAD)
        let end = Int(TagUtility.PAGE_SIZE) * Int(Ntag215Pages.MODEL_TAIL + 1)

        return self.subdata(in: start..<end).hexDescription
    }
    
    var head: String {
        let start = Int(TagUtility.PAGE_SIZE) * Int(Ntag215Pages.MODEL_HEAD)
        let end = Int(TagUtility.PAGE_SIZE) * Int(Ntag215Pages.MODEL_HEAD + 1)
        
        return self.subdata(in: start..<end).hexDescription
    }
    
    var tail: String {
        let start = Int(TagUtility.PAGE_SIZE) * Int(Ntag215Pages.MODEL_TAIL)
        let end = Int(TagUtility.PAGE_SIZE) * Int(Ntag215Pages.MODEL_TAIL + 1)
        
        return self.subdata(in: start..<end).hexDescription
    }
    
    func page(_ pageNum: UInt8) -> Data {
        let start = Int(pageNum) * Int(TagUtility.PAGE_SIZE)
        let end = Int(pageNum) * Int(TagUtility.PAGE_SIZE) + Int(TagUtility.PAGE_SIZE)
        return subdata(in: start..<end)
    }
    
    init (hex: String) {
        let hexArray = hex.trimmingCharacters(in: NSCharacterSet.whitespaces).components(separatedBy: " ")
        let hexBytes: [UInt8] = hexArray.map({ UInt8($0, radix: 0x10)! })
        self.init(hexBytes)
    }
}
