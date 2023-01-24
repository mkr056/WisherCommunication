//
//  FollowerFollowingListView.swift
//  Wisher
//
//  Created by Artem Mkr on 24.01.2023.
//

import SwiftUI
import FirebaseFirestore

struct FollowerFollowingListView: View {
    var user: User // the user for which to display all the relevant data
    var showFollowers: Bool // to determine whether to show the follower list or following
    @State private var workingUsers: [User] = [] // used to store all the relevant users (followers/following) to display in the list
    
    var body: some View {
        List {
            ForEach(workingUsers, id: \.self) { user in
                NavigationLink {
                    ReusableProfileContent(user: user)
                } label: {
                    Text(user.username)
                }
                
            }
        }
        .task {
            var users = [User]()
            if showFollowers {
                for workingUser in user.followerIDs {
                    guard let workingUser = try? await Firestore.firestore().collection("Users").document(workingUser).getDocument(as: User.self) else { return }
                    users.append(workingUser)
                }

            } else {
                for workingUser in user.followingIDs {
                    guard let workingUser = try? await Firestore.firestore().collection("Users").document(workingUser).getDocument(as: User.self) else { return }
                    users.append(workingUser)
                }
            }
            await MainActor.run {
                workingUsers = users
            }
        }
        .navigationTitle(user.username)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FollowerFollowingListView_Previews: PreviewProvider {
    static var previews: some View {
        FollowerFollowingListView(user: User(username: "vdvs", userBio: "fdsfsd", userBioLink: "vsvsd", userUID: "dvdv", userEmail: "dsvdsv", userProfileURL: URL(string: "dsvdsv")!), showFollowers: true)
    }
}
