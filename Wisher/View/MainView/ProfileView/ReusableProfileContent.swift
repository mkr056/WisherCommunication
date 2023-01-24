//
//  ReusableProfileContent.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI
import FirebaseFirestore

// Why? Since our app contains a search user feature, making this component reusable will avoid more redundant codes and also make it easy to display user details simply with a User Model Object
struct ReusableProfileContent: View {
    var user: User // the user for which to display all the relevant data
    @State private var fetchedPosts: [Post] = [] // stores all the posts to show in the profile for a given user
    @State private var createNewPost: Bool = false // for triggering create new post view as fullscreen cover
    
    var userUID: String = UserDefaults.standard.string(forKey: "user_UID") ?? "" // getting the current user's UID
    var profileOfSelf: Bool {
        userUID == user.userUID // checking whether the current use is watching his own profile or someone else's. Changing the UI respectively
    }
    
    @State private var buttonText: String = ""

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                VStack(spacing: 12) {
                    HStack {
                        WebImage(url: user.userProfileURL).placeholder {
                            // MARK: Placeholder Image
                            Image(systemName: "person.fill")
                                .resizable()
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        Spacer()
                        HStack {
                            Button {
                                // posts
                            } label: {
                                VStack(alignment: .center) {
                                    Text("\(fetchedPosts.count)")
                                    Text("Posts")
                                }
                            }
                            
                            Button {
                                // followers
                            } label: {
                                VStack(alignment: .center) {
                                    Text("\(user.followerIDs.count)")
                                    Text("Followers")
                                }
                            }
                            
                            Button {
                                // following
                            } label: {
                                VStack(alignment: .center) {
                                    Text("\(user.followingIDs.count)")
                                    Text("Following")
                                }
                            }


                            
                        }
                        .tint(.primary)
                        .font(.callout)
                        .hAlign(.center)
                        .minimumScaleFactor(0.5)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
//                        Text(user.username)
//                            .font(.title3)
//                            .fontWeight(.semibold)
                        Text(user.userBio)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(3)
                        
                        // MARK: Displaying Bio Link, If Provided When Signing Up Profile
                        if let bioLink = URL(string: user.userBioLink) {
                            Link(user.userBioLink, destination: bioLink)
                                .font(.callout)
                                .tint(.blue)
                                .lineLimit(1)
                        }
                        
                        Button {
                            if profileOfSelf {
                                createNewPost.toggle()
                            } else {
                                followUser()
                                getButtonText()

                            }

                        } label: {
                            Text(profileOfSelf ? "Add new post" : buttonText)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .hAlign(.center)
                                .fillView(.secondary, vPadding: 5)
                        }
                       .padding(.top, 10)

                        
                    }
                    .hAlign(.leading)
                }
                
                Text("Posts")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .hAlign(.leading)
                    .padding(.top, 10)
                    .padding(.bottom, 15)
                
                ReusablePostsView(basedOnUID: true, uid: user.userUID, feedPosts: $fetchedPosts) // this is why we created ReusablePostView, so that when you pass the user uid, is simply fetches all the posts associated with the user UID, avoiding redundancy codes
                
            }
            .padding(15)
        }
        .fullScreenCover(isPresented: $createNewPost) {
            CreateNewPost { post in
                fetchedPosts.insert(post, at: 0)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(user.username)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            buttonText = user.followerIDs.contains(userUID) ? "Unfollow" : "Follow"
        }

    }
    
    
    func getButtonText() {
        (buttonText == "Follow") ? (buttonText = "Unfollow") : (buttonText = "Follow")
    }
    

    func followUser() {
        Task {
            guard let loggedInUser = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self) else { return }
            if loggedInUser.followingIDs.contains(user.userUID) { // if the currently logged in user already has the chose user in the following list, then unfollow
                // MARK: Removing User ID From the Array
                try await Firestore.firestore().collection("Users").document(loggedInUser.userUID).updateData([
                    "followingIDs": FieldValue.arrayRemove([user.userUID])
                ])
                
                try await Firestore.firestore().collection("Users").document(user.userUID).updateData([
                    "followerIDs": FieldValue.arrayRemove([loggedInUser.userUID])
                ])
            } else {
                // MARK: Adding User ID To Liked Array and Removing our ID from Disliked Array (if Added in prior)
                try await Firestore.firestore().collection("Users").document(loggedInUser.userUID).updateData([
                    "followingIDs": FieldValue.arrayUnion([user.userUID])
                ])
                
                try await Firestore.firestore().collection("Users").document(user.userUID).updateData([
                    "followerIDs": FieldValue.arrayUnion([loggedInUser.userUID])
                ])
            }


        }
    }
}


struct ReusableProfileContent_Previews: PreviewProvider {
    static var previews: some View {
        ReusableProfileContent(user: User(username: "test", userBio: "just testing", userBioLink: "https://www.google.com/", userUID: "321321321", userEmail: "testing@gmail.com", userProfileURL: URL(string: "https://www.google.com/")!))
    }
}
