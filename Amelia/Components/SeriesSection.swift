//
//  SeriesSection.swift
//  Amelia
//
//  Created by Amy Collector on 10/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct SeriesSection<HeaderContent: View, EmptyListContent: View>: View {
    let series: [GameSeries]
    let subCategory: AmiibosByCategory.SubCategory
    let title: LocalizedStringKey
    let loading: Bool
    let slot: UInt8?
    let headerContent: HeaderContent
    let emptyListContent: EmptyListContent
    
    init(series: [GameSeries] = [GameSeries](), subCategory: AmiibosByCategory.SubCategory = .owned, title: LocalizedStringKey, loading: Bool, @ViewBuilder headerContent: () -> HeaderContent, @ViewBuilder emptyListContent: () -> EmptyListContent) {
        self.series = series
        self.subCategory = subCategory
        self.title = title
        self.loading = loading
        self.slot = nil
        self.headerContent = headerContent()
        self.emptyListContent = emptyListContent()
    }
    
    init(series: [GameSeries] = [GameSeries](), subCategory: AmiibosByCategory.SubCategory = .owned, title: LocalizedStringKey, loading: Bool, slot: UInt8?, @ViewBuilder headerContent: () -> HeaderContent, @ViewBuilder emptyListContent: () -> EmptyListContent) {
        self.series = series
        self.subCategory = subCategory
        self.title = title
        self.loading = loading
        self.slot = slot
        self.headerContent = headerContent()
        self.emptyListContent = emptyListContent()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(self.title)
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                Spacer()
                self.headerContent
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
            }
            if self.series.count > 0 {
                ZStack {
                    BlurView(style: .systemThickMaterial)
                    VStack(spacing: 0) {
                        ForEach(self.series, id:\.name) { item in
                            SeriesRow(category: item.name, subCategory: self.subCategory, count: item.count, disabled: self.loading, last: self.isLast(item), slot: self.slot)
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            else {
                self.emptyListContent
            }
        }
    }
    
    private func isLast(_ item: GameSeries) -> Bool {
        return series.last?.name == item.name
    }
}

fileprivate struct SeriesRow: View {
    let category: String
    let subCategory: AmiibosByCategory.SubCategory
    let count: Int
    let disabled: Bool
    let last: Bool
    let slot: UInt8?
    
    init(category: String, subCategory: AmiibosByCategory.SubCategory, count: Int, disabled: Bool, last: Bool) {
        self.category = category
        self.subCategory = subCategory
        self.count = count
        self.disabled = disabled
        self.last = last
        self.slot = nil
    }
    
    init(category: String, subCategory: AmiibosByCategory.SubCategory, count: Int, disabled: Bool, last: Bool, slot: UInt8?) {
        self.category = category
        self.subCategory = subCategory
        self.count = count
        self.disabled = disabled
        self.last = last
        self.slot = slot
    }

    var body: some View {
        NavigationLink(destination: AmiibosByCategory(category: self.category, subCategory: self.subCategory, slot: self.slot)) {
            VStack(alignment: .center, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "gamecontroller")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .opacity(0.7)
                    Text(self.category)
                        .lineLimit(1)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(self.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    ChevronRight()
                }
                .padding(.horizontal)
                .frame(height: 55)
                if !self.last {
                    Divider()
                }
            }
        }
        .disabled(self.disabled)
        .opacity(self.disabled ? 0.6 : 1.0)
        .accessibility(identifier: self.category)
    }
}

//struct SeriesSection_Previews: PreviewProvider {
//    static var previews: some View {
//        SeriesSection(title: "owned") {
//            Button(action: {}) {
//                Image(systemName: "plus.circle.fill")
//            }
//        }
//        .padding()
//        .previewLayout(.fixed(width: 375, height: 300))
//    }
//}
