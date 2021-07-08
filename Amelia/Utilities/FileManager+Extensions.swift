//
//  FileManager+Extensions.swift
//  Amelia
//
//  Created by Amy Collector on 13/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation

extension FileManager {
    static var userDirectoryUrl: URL {
        get {
            return try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        }
    }
    
    static var importFileUrls: [URL] {
        get {
            let items = try? FileManager.default.contentsOfDirectory(at: FileManager.userDirectoryUrl, includingPropertiesForKeys: [], options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants])
            
            return items!.filter({ item -> Bool in
                return item.pathExtension == "bin" && !item.lastPathComponent.contains("key_retail")
            })
        }
    }
}
