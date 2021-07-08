//
//  SyncConstants.swift
//  Amii
//
//  Created by Amy Collector on 01/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import CloudKit

struct SyncConstants {
    static let containerIdentifier: String = "iCloud.app.amycollector.Amii"
    
    public static let customZoneId: CKRecordZone.ID = {
        CKRecordZone.ID(zoneName: "BackupZone", ownerName: CKCurrentUserDefaultName)
    }()
}
