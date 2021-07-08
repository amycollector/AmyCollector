//
//  CloudKitHelper.swift
//  Amii
//
//  Created by Amy Collector on 01/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import CloudKit
import os.log

final class CloudKitHelper {
    static let shared: CloudKitHelper = CloudKitHelper()
    
    let log = OSLog(subsystem: "app.amycollector.Amii", category: String(describing: CloudKitHelper.self))
    
    private(set) lazy var container: CKContainer = {
        CKContainer(identifier: SyncConstants.containerIdentifier)
    }()

    private(set) lazy var privateDatabase: CKDatabase = {
        container.privateCloudDatabase
    }()

    private(set) lazy var privateSubscriptionId: String = {
        return "\(SyncConstants.customZoneId.zoneName).subscription"
    }()
    
    private let workQueue = DispatchQueue(label: "SyncEngine.Work", qos: .userInitiated)
    private let cloudQueue = DispatchQueue(label: "SyncEngine.Cloud", qos: .userInitiated)
    
    private lazy var cloudOperationQueue: OperationQueue = {
        let q = OperationQueue()

        q.underlyingQueue = cloudQueue
        q.name = "SyncEngine.Cloud"
        q.maxConcurrentOperationCount = 1

        return q
    }()
    
    
    private lazy var createdCustomZoneKey: String = {
        return "CREATEDZONE-\(SyncConstants.customZoneId.zoneName)"
    }()
    
    private var createdCustomZone: Bool {
        get {
            return UserDefaults.standard.bool(forKey: createdCustomZoneKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: createdCustomZoneKey)
        }
    }
    
    private lazy var createdPrivateSubscriptionKey: String = {
        return "CREATEDSUBDB-\(SyncConstants.customZoneId.zoneName)"
    }()

    private var createdPrivateSubscription: Bool {
        get {
            return UserDefaults.standard.bool(forKey: createdPrivateSubscriptionKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: createdPrivateSubscriptionKey)
        }
    }
    
    private lazy var privateChangeTokenKey: String = {
        return "TOKEN-\(SyncConstants.customZoneId.zoneName)"
    }()

    private var privateChangeToken: CKServerChangeToken? {
        get {
            guard let data = UserDefaults.standard.data(forKey: privateChangeTokenKey) else { return nil }
            guard !data.isEmpty else { return nil }

            do {
                let token = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)

                return token
            } catch {
                os_log("Failed to decode CKServerChangeToken from defaults key privateChangeToken", log: log, type: .error)
                return nil
            }
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.setValue(Data(), forKey: privateChangeTokenKey)
                return
            }

            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: true)

                UserDefaults.standard.set(data, forKey: privateChangeTokenKey)
            } catch {
                os_log("Failed to encode private change token: %{public}@", log: self.log, type: .error, String(describing: error))
            }
        }
    }
    
    private lazy var cloudKitQueue: CloudKitQueue = CloudKitQueue(for: self.privateDatabase)
    
    init() {
        self.prepareCloudEnvironment { [weak self] in
            guard self != nil else { return }
        }
    }
    
    private func prepareCloudEnvironment(then block: @escaping () -> Void) {
        self.workQueue.async { [weak self] in
            guard let self = self else { return }

            self.createCustomZoneIfNeeded()
            self.cloudOperationQueue.waitUntilAllOperationsAreFinished()
            guard self.createdCustomZone else { return }

            self.createPrivateSubscriptionsIfNeeded()
            self.cloudOperationQueue.waitUntilAllOperationsAreFinished()
            guard self.createdPrivateSubscription else { return }

            DispatchQueue.main.async { block() }
        }
    }
    
    private func createCustomZoneIfNeeded() {
        guard !createdCustomZone else {
            os_log("Already have custom zone, skipping creation but checking if zone really exists", log: log, type: .debug)

            checkCustomZone()

            return
        }

        os_log("Creating CloudKit zone %@", log: log, type: .info, SyncConstants.customZoneId.zoneName)

        let zone = CKRecordZone(zoneID: SyncConstants.customZoneId)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone], recordZoneIDsToDelete: nil)

        operation.modifyRecordZonesCompletionBlock = { [weak self] _, _, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to create custom CloudKit zone: %{public}@",
                       log: self.log,
                       type: .error,
                       String(describing: error))

                error.retryCloudKitOperationIfPossible(self.log) { self.createCustomZoneIfNeeded() }
            } else {
                os_log("Zone created successfully", log: self.log, type: .info)
                self.createdCustomZone = true
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = privateDatabase

        self.cloudOperationQueue.addOperation(operation)
    }
    
    private func checkCustomZone() {
        let operation = CKFetchRecordZonesOperation(recordZoneIDs: [SyncConstants.customZoneId])
        
        operation.fetchRecordZonesCompletionBlock = { [weak self] ids, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to check for custom zone existence: %{public}@", log: self.log, type: .error, String(describing: error))

                if !error.retryCloudKitOperationIfPossible(self.log, with: { self.checkCustomZone() }) {
                    os_log("Irrecoverable error when fetching custom zone, assuming it doesn't exist: %{public}@", log: self.log, type: .error, String(describing: error))

                    DispatchQueue.main.async {
                        self.createdCustomZone = false
                        self.createCustomZoneIfNeeded()
                    }
                }
            } else if ids == nil || ids?.count == 0 {
                os_log("Custom zone reported as existing, but it doesn't exist. Creating.", log: self.log, type: .error)
                self.createdCustomZone = false
                self.createCustomZoneIfNeeded()
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = self.privateDatabase

        self.cloudOperationQueue.addOperation(operation)
    }
    
    private func createPrivateSubscriptionsIfNeeded() {
        guard !createdPrivateSubscription else {
            os_log("Already subscribed to private database changes, skipping subscription but checking if it really exists", log: log, type: .debug)

            checkSubscription()

            return
        }

        let subscription = CKRecordZoneSubscription(zoneID: SyncConstants.customZoneId, subscriptionID: privateSubscriptionId)

        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true

        subscription.notificationInfo = notificationInfo
        subscription.recordType = .characterData

        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)

        operation.database = privateDatabase
        operation.qualityOfService = .userInitiated

        operation.modifySubscriptionsCompletionBlock = { [weak self] _, _, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to create private CloudKit subscription: %{public}@",
                       log: self.log,
                       type: .error,
                       String(describing: error))

                error.retryCloudKitOperationIfPossible(self.log) { self.createPrivateSubscriptionsIfNeeded() }
            } else {
                os_log("Private subscription created successfully", log: self.log, type: .info)
                self.createdPrivateSubscription = true
            }
        }

        self.cloudOperationQueue.addOperation(operation)
    }

    private func checkSubscription() {
        let operation = CKFetchSubscriptionsOperation(subscriptionIDs: [privateSubscriptionId])

        operation.fetchSubscriptionCompletionBlock = { [weak self] ids, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to check for private zone subscription existence: %{public}@", log: self.log, type: .error, String(describing: error))

                if !error.retryCloudKitOperationIfPossible(self.log, with: { self.checkSubscription() }) {
                    os_log("Irrecoverable error when fetching private zone subscription, assuming it doesn't exist: %{public}@", log: self.log, type: .error, String(describing: error))

                    DispatchQueue.main.async {
                        self.createdPrivateSubscription = false
                        self.createPrivateSubscriptionsIfNeeded()
                    }
                }
            } else if ids == nil || ids?.count == 0 {
                os_log("Private subscription reported as existing, but it doesn't exist. Creating.", log: self.log, type: .error)

                DispatchQueue.main.async {
                    self.createdPrivateSubscription = false
                    self.createPrivateSubscriptionsIfNeeded()
                }
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = privateDatabase

        self.cloudOperationQueue.addOperation(operation)
    }
    
    // MARK: - Upload Local Changes
    
    func uploadLocalChanges(_ records: [CKRecord], slow: Bool = false) {
        guard !records.isEmpty else { return }
        
        if slow {
            for record in records {
                self.cloudKitQueue.slowSave(record) { _,_ in }
            }
            
            return
        }
        
        for record in records {
            self.cloudKitQueue.save(record) { a,error in
                
            }
        }
    }
    
    func removeItems(_ records: [CKRecord], slow: Bool = false) {
        guard !records.isEmpty else { return }
        
        if slow {
            records.forEach { id in
                self.cloudKitQueue.slowDelete(id.recordID)
            }
            
            return
        }
        
        records.forEach { id in
            self.cloudKitQueue.delete(id.recordID)
        }
    }
    
    func fetchCloudChanges(completion: @escaping ([CharacterData]) -> Void) {
        let query = CKQuery(recordType: .characterData, predicate: NSPredicate(value: true))
        let operation = CKQueryOperation(query: query)
        
        var items: [CharacterData] = [CharacterData]()
        
        operation.recordFetchedBlock = { record in
            items.append(CharacterData(record: record))
        }
        
        operation.queryCompletionBlock = {(cursor, error) in
            if error != nil {
                completion([])
                
                return
            }
            
            completion(items)
        }
        
        self.cloudKitQueue.add(operation)
    }
    
    func fetchRemoteChanges(_ completion: @escaping ([CKRecord], [CKRecord.ID], Error?) -> Void) {
        var changedRecords: [CKRecord] = []
        var deletedRecordIDs: [CKRecord.ID] = []

        let operation = CKFetchRecordZoneChangesOperation()

        let token: CKServerChangeToken? = privateChangeToken

        let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration(
            previousServerChangeToken: token,
            resultsLimit: nil,
            desiredKeys: nil
        )

        operation.configurationsByRecordZoneID = [SyncConstants.customZoneId: config]

        operation.recordZoneIDs = [SyncConstants.customZoneId]
        operation.fetchAllChanges = true

        operation.recordZoneChangeTokensUpdatedBlock = { [weak self] _, changeToken, _ in
            guard let self = self else { return }

            guard let changeToken = changeToken else { return }

            self.privateChangeToken = changeToken
        }

        operation.recordZoneFetchCompletionBlock = { [weak self] _, token, _, _, error in
            guard let self = self else { return }

            if let error = error as? CKError {
                os_log("Failed to fetch record zone changes: %{public}@",
                       log: self.log,
                       type: .error,
                       String(describing: error))

                if error.code == .changeTokenExpired {
                    os_log("Change token expired, resetting token and trying again", log: self.log, type: .error)

                    self.privateChangeToken = nil

                    DispatchQueue.main.async { self.fetchRemoteChanges(completion) }
                } else {
                    error.retryCloudKitOperationIfPossible(self.log) { self.fetchRemoteChanges(completion) }
                }
            } else {
                os_log("Commiting new change token", log: self.log, type: .debug)

                self.privateChangeToken = token
            }
        }

        operation.recordChangedBlock = { changedRecords.append($0) }

        operation.recordWithIDWasDeletedBlock = { recordID, _ in
            // In the future we may need to use the second arg to this closure and map
            // between record types and deleted record IDs (when we need to sync more types)
            deletedRecordIDs.append(recordID)
        }

        operation.fetchRecordZoneChangesCompletionBlock = { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                os_log("Failed to fetch record zone changes: %{public}@",
                       log: self.log,
                       type: .error,
                       String(describing: error))

                error.retryCloudKitOperationIfPossible(self.log) { self.fetchRemoteChanges(completion) }
            } else {
                os_log("Finished fetching record zone changes", log: self.log, type: .info)

                completion(changedRecords, deletedRecordIDs, nil)
            }
        }

        operation.qualityOfService = .userInitiated
        operation.database = privateDatabase

        cloudOperationQueue.addOperation(operation)
    }
    
    func processSubscriptionNotification(with userInfo: [AnyHashable : Any], completion: @escaping (Bool) -> Void) {
        os_log("%{public}@", log: log, type: .debug, #function)

        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            os_log("Not a CKNotification", log: self.log, type: .error)
            
            completion(false)

            return
        }

        guard notification.subscriptionID == privateSubscriptionId else {
            os_log("Not our subscription ID", log: self.log, type: .debug)
            completion(false)

            return
        }

        os_log("Received remote CloudKit notification for user data", log: log, type: .debug)

        completion(true)
    }
}

fileprivate extension Error {
    /// Retries a CloudKit operation if the error suggests it
    ///
    /// - Parameters:
    ///   - log: The logger to use for logging information about the error handling, uses the default one if not set
    ///   - block: The block that will execute the operation later if it can be retried
    /// - Returns: Whether or not it was possible to retry the operation
    @discardableResult func retryCloudKitOperationIfPossible(_ log: OSLog? = nil, with block: @escaping () -> Void) -> Bool {
        let effectiveLog: OSLog = log ?? .default

        guard let effectiveError = self as? CKError else { return false }

        guard let retryDelay: Double = effectiveError.retryAfterSeconds else {
            os_log("Error is not recoverable", log: effectiveLog, type: .error)
            return false
        }

        os_log("Error is recoverable. Will retry after %{public}f seconds", log: effectiveLog, type: .error, retryDelay)

        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
            block()
        }

        return true
    }
}
