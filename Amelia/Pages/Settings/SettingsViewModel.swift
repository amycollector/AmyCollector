//
//  SettingsViewModel.swift
//  Amelia
//
//  Created by Amy Collector on 12/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation

final class SettingsViewModel: ObservableObject {
    func checkForUpdates(completion: @escaping () -> Void) {
        let updateUrl = URL(string: "https://amycollector.app/data/updates.json")
        URLSession.shared.dataTask(with: updateUrl!){ updateData, response, error in

            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d y HH:mm zzz"
            UserDefaults.lastUpdated = formatter.string(from: date)

            completion()
            
            if let data = updateData {
                var rawData: [AmiiboData] = []
                
                do {
                    rawData = try JSONDecoder().decode([AmiiboData].self, from: data)
                } catch {
                    print(error)
                }
                
                guard rawData.count > 0 else { return }
                
                let amiiboData = rawData.map({ (raw: AmiiboData) -> Amiibo in
                    return Amiibo(id: "\(raw.head)\(raw.tail)", name: raw.name, amiiboSeries: raw.amiiboSeries, gameSeries: raw.gameSeries, type: raw.type, image: raw.image, data: nil)
                })
                
                AmiiboRepository.shared.write { db in
                    amiiboData.forEach { item in
                        try? item.insert(db)
                    }
                }
            }
        }
        .resume()
    }
}
