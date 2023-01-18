//
//  ReusableProfileContent.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI
import SDWebImageSwiftUI

// Why? Since our app contains a search user feature, making this component reusable will avoid more redundant codes and also make it easy to display user details simply with a User Model Object
struct ReusableProfileContent: View {
    var user: User // the user for which to display all the relevant data
    @State private var fetchedPosts: [Post] = [] // stores all the posts to show in the profile for a given user
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack {
                HStack(spacing: 12) {
                    WebImage(url: user.userProfileURL).placeholder {
                        // MARK: Placeholder Image
                        Image(systemName: "person.fill")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(user.username)
                            .font(.title3)
                            .fontWeight(.semibold)
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
                        
                    }
                    .hAlign(.leading)
                }
                
                Text("Posts")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .hAlign(.leading)
                    .padding(.vertical, 15)
                
                ReusablePostsView(basedOnUID: true, uid: user.userUID, posts: $fetchedPosts) // this is why we created ReusablePostView, so that when you pass the user uid, is simply fetches all the posts associated with the user UID, avoiding redundancy codes
                
            }
            .padding(15)
        }
    }
}

