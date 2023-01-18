//
//  SearchUserView.swift
//  Wisher
//
//  Created by Artem Mkr on 16.01.2023.
//

import SwiftUI
import FirebaseFirestore

struct SearchUserView: View {
    
    // MARK: View Properties
    @State private var fetchedUsers: [User] = [] // stores the result of the search
    @State private var searchText: String = "" // for search text field
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {

        List {
            ForEach(fetchedUsers) { user in
                NavigationLink {
                    ReusableProfileContent(user: user) // this is why we created the ReusableProfileView, so that if you pass it a user object, it will simply display all of the user's details, avoiding redundancy codes
                } label: {
                    Text(user.username)
                        .font(.callout)
                        .hAlign(.leading)
                }

            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search User")
        .searchable(text: $searchText)
        .onSubmit(of: .search, {
            // MARK: Fetch User From Firebase
            Task { await searchUsers() }
        })
        .onChange(of: searchText, perform: { newValue in
            if newValue.isEmpty {
                fetchedUsers.removeAll()
                
            }
        })
    }
    
    func searchUsers() async {
        do {

            let documents = try await Firestore.firestore().collection("Users") // because there is no way to search for "String Contains" in Firebase Firestore, we must use greater of less than equivalence to find strings in the document
                .whereField("username", isGreaterThanOrEqualTo: searchText) // since I've stored the username in the way the user typed it, I am passing the search text directly instead of making it lowercased
                .whereField("username", isLessThanOrEqualTo: "\(searchText)\u{f8ff}")
                .getDocuments()
            let users = try documents.documents.compactMap { doc -> User? in
                try doc.data(as: User.self)
            }
            // MARK: UI Must be Updated on Main Thread
            await MainActor.run(body: {
                fetchedUsers = users
            })

        } catch {
            print(error.localizedDescription)
        }
    }
}

struct SearchUserView_Previews: PreviewProvider {
    static var previews: some View {
        SearchUserView()
    }
}
