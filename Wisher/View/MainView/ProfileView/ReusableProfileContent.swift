//
//  ReusableProfileContent.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI
import FirebaseAuth
import SDWebImageSwiftUI

// Why? Since our app contains a search user feature, making this component reusable will avoid more redundant codes and also make it easy to display user details simply with a User Model Object
struct ReusableProfileContent: View {
    var user: User // the user for which to display all the relevant data
    @State private var fetchedPosts: [Post] = [] // stores all the posts to show in the profile for a given user
    @State private var createNewPost: Bool = false // for triggering create new post view as fullscreen cover
    
    var profileOfSelf: Bool {
        UserDefaults.standard.string(forKey: "user_UID") == user.userUID // checking whether the current use is watching his own profile or someone else's. Changing the UI respectively
    }

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
                                    Text("12")
                                    Text("Posts")
                                }
                            }
                            
                            Button {
                                // followers
                            } label: {
                                VStack(alignment: .center) {
                                    Text("52")
                                    Text("Followers")
                                }
                            }
                            
                            Button {
                                // following
                            } label: {
                                VStack(alignment: .center) {
                                    Text("932")
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
                            createNewPost.toggle()

                        } label: {
                            Text(profileOfSelf ? "Add new post" : "Follow")
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
                
                ReusablePostsView(basedOnUID: true, uid: user.userUID, posts: $fetchedPosts) // this is why we created ReusablePostView, so that when you pass the user uid, is simply fetches all the posts associated with the user UID, avoiding redundancy codes
                
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
    }
}


struct ReusableProfileContent_Previews: PreviewProvider {
    static var previews: some View {
        ReusableProfileContent(user: User(username: "test", userBio: "just testing", userBioLink: "https://www.google.com/", userUID: "321321321", userEmail: "testing@gmail.com", userProfileURL: URL(string: "https://www.google.com/")!))
    }
}
