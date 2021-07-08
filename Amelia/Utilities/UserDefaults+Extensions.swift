//
//  UserDefaults+Extensions.swift
//  Amelia
//
//  Created by Amy Collector on 11/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation

extension UserDefaults {
    static var autoSave: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "auto_save_scan")
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "auto_save_scan")
        }
    }
    
    static var dataMigrated: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "data_migrated")
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "data_migrated")
        }
    }

    static var helpShown: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "help_shown")
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "help_shown")
        }
    }
    
    static var identifyAfterRestore: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "identify_after_restore")
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "identify_after_restore")
        }
    }
    
    static var initialCloudSync: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "initial_cloud_sync")
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "initial_cloud_sync")
        }
    }
    
    static var lastUpdated: String {
        get {
            return UserDefaults.standard.string(forKey: "last_update") ?? "Never"
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "last_update")
        }
    }
    
    static var n2EliteSupport: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "n2_elite_support")
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "n2_elite_support")
        }
    }
    
}
