//
//  SearchBar.swift
//  Amii
//
//  Created by Amy Collector on 15/06/2020.
//  Copyright © 2020 Amy Collector. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

struct SearchBar: UIViewRepresentable {
    init(isSearching: Binding<Bool>, placeholder: String, isDisabled: Binding<Bool>, onSearchButtonClicked: ((String, Int) -> Void)? = nil, onCancelButtonClicked: (() -> Void)? = nil) {
        self._isSearching = isSearching
        self._isDisabled = isDisabled

        self.placeholder = NSLocalizedString(placeholder, comment: "")
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onCancelButtonClicked = onCancelButtonClicked
    }

    @Binding var isSearching: Bool
    @Binding var isDisabled: Bool
    
    let placeholder: String
    let onSearchButtonClicked: ((String, Int) -> Void)?
    let onCancelButtonClicked: (() -> Void)?
    
    class Coordinator: NSObject, UISearchBarDelegate {
        private var text: String = ""
        @Binding var isSearching: Bool

        let onSearchButtonClicked: ((String, Int) -> Void)?
        let onCancelButtonClicked: (() -> Void)?
        
        init(isSearching: Binding<Bool>, onSearchButtonClicked: ((String, Int) -> Void)?, onCancelButtonClicked: (() -> Void)?) {
            self._isSearching = isSearching
            self.onSearchButtonClicked = onSearchButtonClicked
            self.onCancelButtonClicked = onCancelButtonClicked
        }
        
        func searchBar(_ searchbar: UISearchBar, textDidChange searchText: String) {
            self.text = searchText
        }
        
        func searchBarTextDidBeginEditing(_ searchbar: UISearchBar) {
            searchbar.setShowsCancelButton(true, animated: true)
//            searchbar.setShowsScope(true, animated: false)
            self.isSearching = true
        }
        
        func searchBarCancelButtonClicked(_ searchbar: UISearchBar) {
            searchbar.endEditing(true)
            searchbar.setShowsCancelButton(false, animated: true)
//            searchbar.setShowsScope(false, animated: false)
            searchbar.text = ""
            self.isSearching = false
            self.onCancelButtonClicked?()
        }
        
        func searchBarSearchButtonClicked(_ searchbar: UISearchBar) {
            searchbar.endEditing(true)
            searchbar.setShowsCancelButton(false, animated: true)
//            searchbar.setShowsScope(true, animated: false)
            self.isSearching = false
            
            self.onSearchButtonClicked?(searchbar.text!, searchbar.selectedScopeButtonIndex)
        }
        
        func searchBarTextDidEndEditing(_ searchbar: UISearchBar) {
            searchbar.setShowsCancelButton(false, animated: true)
//            searchbar.setShowsScope(searchbar.text != nil, animated: false)
            self.isSearching = false
        }
    }
    
    func makeCoordinator() -> SearchBar.Coordinator {
        return SearchBar.Coordinator(isSearching: self.$isSearching, onSearchButtonClicked: self.onSearchButtonClicked, onCancelButtonClicked: self.onCancelButtonClicked)
    }
    
    func makeUIView(context: UIViewRepresentableContext<SearchBar>) -> UISearchBar {
        let searchbar = UISearchBar(frame: .zero)
        searchbar.autocorrectionType = .no
        searchbar.autocapitalizationType = .none
        searchbar.backgroundImage = UIImage()
        searchbar.placeholder = self.placeholder
        searchbar.isUserInteractionEnabled = !self.isDisabled
        searchbar.scopeBarBackgroundImage = UIImage()
//        searchbar.scopeButtonTitles = ["All", "Card", "Figure", "Yarn"]
//        searchbar.showsScopeBar = false
        
        searchbar.delegate = context.coordinator

        return searchbar
    }
    
    func updateUIView(_ searchbar: UISearchBar, context: Context) {
        searchbar.isUserInteractionEnabled = !self.isDisabled
    }
}
