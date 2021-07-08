//
//  AmiibosByCategory.swift
//  Amelia
//
//  Created by Amy Collector on 11/07/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import SwiftUI

struct AmiibosByCategory: View {
    @ObservedObject private(set) var viewModel: AmiibosByCategoryViewModel = AmiibosByCategoryViewModel()

    @State private var searching: Bool = false
    @State private var searchingDisabled: Bool = true
    @State private var initial: Bool = true
    @State private var loading: Bool = true
    @State var showDeleteConfirmation: Bool = false
    @State var itemToDelete: Int? = nil

    let category: String
    let subCategory: SubCategory
    let slot: UInt8?
    
    init(category: String, subCategory: SubCategory) {
        self.category = category
        self.subCategory = subCategory
        self.slot = nil
    }
    
    init(category: String, subCategory: SubCategory, slot: UInt8?) {
        self.category = category
        self.subCategory = subCategory
        self.slot = slot
    }

    var body: some View {
        List {
            Section(header: self.searchBar) {
                if self.viewModel.amiibos.count == 0 {
                    HStack {
                        Spacer()
                        if self.loading {
                            ActivityIndicator(shouldAnimate: self.$loading)
                        }
                        else {
                            Text(self.viewModel.emptyListText)
                                .multilineTextAlignment(.center)
                                .lineLimit(10)
                        }
                        Spacer()
                    }
                }
                ForEach(self.viewModel.amiibos, id: \.id) { item in
                    NavigationLink(destination: CharacterDetails(amiibo: item, slot: self.slot)) {
                        CharacterListItem(amiibo: item)
                    }
                    .disabled(self.searching)
                }
                .onDelete(perform: self.onDelete)
            }
        }
        .listStyle(GroupedListStyle())
        .onAppear(perform: {
            if self.initial {
                self.searchingDisabled = true
                self.viewModel.searchText = ""
                self.initial = false
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                self.viewModel.fetchAmiibos(category: self.category, subCategory: self.subCategory)
                self.searchingDisabled = self.viewModel.amiibos.isEmpty
                self.loading = false
            }
            
        })
        .alert(isPresented: self.$showDeleteConfirmation) {
            self.confirmPopup
        }
        .navigationBarItems(trailing: EditButton().disabled(self.searchingDisabled))
        .navigationBarTitle("\(self.category)", displayMode: .inline)
        .navigationBarHidden(self.searching)
    }
    
    private var searchBar: some View {
        SearchBar(isSearching: self.$searching, placeholder: "character_name_search", isDisabled: self.$searchingDisabled, onSearchButtonClicked: { text, _ in
            self.viewModel.searchText = text
            self.viewModel.fetchAmiibos(category: self.category, subCategory: self.subCategory)
        }, onCancelButtonClicked: {
            self.viewModel.searchText = ""
            self.viewModel.fetchAmiibos(category: self.category, subCategory: self.subCategory)
        })
            .padding(.horizontal, -10)
    }
    
    private var confirmPopup: Alert {
        if self.subCategory == .owned {
            return Alert(title: Text("delete_question"), message: Text("delete_amiibo_confirm"), primaryButton: .cancel(Text("delete_no").bold()), secondaryButton: .destructive(Text("delete_yes"), action: self.deleteData))
        }
        else {
            return Alert(title: Text("remove_wish_list_question"), message: Text("remove_wish_list_amiibo_confirm"), primaryButton: .cancel(Text("remove_wish_list_no").bold()), secondaryButton: .destructive(Text("remove_wish_list_yes"), action: self.deleteData))
        }
    }
    
    private func onDelete(at: IndexSet) {
        self.itemToDelete = at.first
        self.showDeleteConfirmation = true
    }
    
    private func deleteData() {
        if self.itemToDelete == nil {
            return
        }

        self.viewModel.clearAmiiboData(at: self.itemToDelete!)
        self.viewModel.fetchAmiibos(category: self.category, subCategory: self.subCategory)
    }
    
    enum SubCategory {
        case owned
        case wanted
    }
}

struct AmiibosByCategory_Previews: PreviewProvider {
    static var previews: some View {
        AmiibosByCategory(category: "Animal Crossing", subCategory: .owned)
    }
}
