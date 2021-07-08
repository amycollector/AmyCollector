//
//  Amiitool.swift
//  Amii
//
//  Created by Amy Collector on 13/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import amiitool

struct Amiitool {
    private var keys: UnsafeMutablePointer<nfc3d_amiibo_keys> = UnsafeMutablePointer<nfc3d_amiibo_keys>.allocate(capacity: 1)
    
    public init(_ keypath: String) {
        if (!nfc3d_amiibo_load_keys(self.keys, keypath)) {
            print("key_retail.bin could not be found in \(keypath)")
        }
    }
    
    public func decrypt(_ tag: Data) -> Data {
        let unsafeTag = tag.unsafeBytes
        let output = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(TagUtility.FULL_DATA_SIZE))

        if (!nfc3d_amiibo_unpack(keys, unsafeTag, output)) {
            print("Invalid tag signature!")
        }

        return Data(bytes: output, count: Int(TagUtility.FULL_DATA_SIZE))
    }
    
    public func encrypt(_ plain: Data) -> Data {
        let unsafePlain = plain.unsafeBytes
        let newImage = UnsafeMutablePointer<UInt8>.allocate(capacity: Int(TagUtility.FULL_DATA_SIZE))

        nfc3d_amiibo_pack(keys, unsafePlain, newImage)

        return Data(bytes: newImage, count: Int(TagUtility.FULL_DATA_SIZE))
    }
}
