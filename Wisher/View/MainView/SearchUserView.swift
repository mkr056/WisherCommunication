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
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    @Environment(\.dismiss) private var dismiss
    var body: some View {

        List {
            ForEach(fetchedUsers) { user in
                NavigationLink {
                    ReusableProfileContent(user: user)
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

            let documents = try await Firestore.firestore().collection("Users")
                .whereField("username", isGreaterThanOrEqualTo: searchText)
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
