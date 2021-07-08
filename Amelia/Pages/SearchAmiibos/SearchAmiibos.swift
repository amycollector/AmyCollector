//
//  SearchAmiibos.swift
//  Amy
//
//  Created by Amy Collector on 13/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI
import GRDB

struct SearchAmiibos: View {
//    @ObservedObject private(set) var viewModel: SearchAmiibosViewModel = SearchAmiibosViewModel()

    @State private var searching: Bool = false
    @State private var searchingDisabled: Bool = false
    @State private var emptyMessage: LocalizedStringKey = "wish_list_search"
    @State private var amiibos: [Amiibo] = [Amiibo]()
    @State private var searchText: String = ""

    var body: some View {
        List{
            Section(header: self.searchBar) {
                if self.amiibos.count == 0 {
                    HStack {
                        Spacer()
                        Text(self.emptyMessage)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                }
                ForEach(self.amiibos, id: \.id) { item in
                    NavigationLink(destination: CharacterDetails(amiibo: item)) {
                        CharacterListItem(amiibo: item)
                    }
                    .disabled(self.searching)
                }
            }
        }
        .listStyle(GroupedListStyle())
        .navigationBarTitle("all_amiibos", displayMode: .inline)
        .navigationBarHidden(self.searching)
    }
    
    private var searchBar: some View {
        SearchBar(isSearching: self.$searching, placeholder: "character_name_search", isDisabled: self.$searchingDisabled, onSearchButtonClicked: { text, _ in
            self.searchText = text
            self.fetchAmiibos()
            self.emptyMessage = "wish_list_search_no_result \(text)"
        }, onCancelButtonClicked: {
            self.searchText = ""
            self.fetchAmiibos()
            self.emptyMessage = "wish_list_search"
        })
            .padding(.horizontal, -10)
    }
    
    private func fetchAmiibos(includeOwned: Bool = false) {
        guard self.searchText.trimmingCharacters(in: CharacterSet(charactersIn: " ")) != "" else {
            self.amiibos = [Amiibo]()

            return
        }

        AmiiboRepository.shared.read { db in
            if includeOwned {
                let amiibos = try? Amiibo
                    .filter(Column("name").like("%\(self.searchText)%"))
                    .order([Column("gameSeries").asc, Column("name").asc])
                    .fetchAll(db)
                
                self.amiibos = amiibos ?? [Amiibo]()
                
                return
            }
            
            let amiibos = try? Amiibo
                .filter(Column("data") == nil && Column("owned") == false && Column("wanted") == false)
                .filter(Column("name").like("%\(self.searchText)%"))
                .order([Column("gameSeries").asc, Column("name").asc])
                .fetchAll(db)
            
            self.amiibos = amiibos ?? [Amiibo]()
            print(self.amiibos.count)
        }
    }
}

struct SearchAmiibos_Previews: PreviewProvider {
    static var previews: some View {
        SearchAmiibos()
    }
}
