//
//  SettingsView.swift
//  Wisher
//
//  Created by Artem Mkr on 26.01.2023.
//

import SwiftUI

struct SettingsView: View {
    @State private var searchText: String = "" // for search text field
    let menuItems: [String] = ["Notifications", "Account", "App Settings", "Blocked", "About", "Help", "Add account", "Delete account"]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(menuItems, id: \.self) { item in
                    NavigationLink {
                        Text(item) // this is why we created the ReusableProfileView, so that if you pass it a user object, it will simply display all of the user's details, avoiding redundancy codes
                    } label: {
                        Text(item)
                            .font(.callout)
                            .hAlign(.leading)
                    }
                    
                }
            }
            .listStyle(.plain)
            
            
            
            .searchable(text: $searchText,
                   placement: .navigationBarDrawer(displayMode: .always))
            .onSubmit(of: .search, {
                // MARK: Fetch User From Firebase
                
            })
            .onChange(of: searchText, perform: { newValue in
                if newValue.isEmpty {
                    // fetchedUsers.removeAll()
                    
                }
            })
        }
    }
    
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
