//
//  PostCardView.swift
//  Wisher
//
//  Created by Artem Mkr on 16.01.2023.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage

struct PostCardView: View {
    var post: Post // post for which information has to be displayed
    @ObservedObject var copyingPost: CopyingPost
    
    // MARK: Callbacks
    var onUpdate: (Post) -> () // action to be run on post when interaction happened
    var onDelete: () -> ()
    // MARK: View Properties
    @AppStorage("user_UID") private var userUID: String = "" // getting the current user's UID
    @State private var docListener: ListenerRegistration? // for live updates
    
    @State private var userProfileToShow: User? // for storing the user based on the tapped post, whose profile will be shown
    @State private var showUserProfile: Bool = false // for triggering navigation link (showing selected user's profile)
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            WebImage(url: post.userProfileURL)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 35, height: 35)
                .clipShape(Circle())
                .onTapGesture {
                    Task {
                        await getUserProfileToShow()
                    }
                    showUserProfile.toggle()
                }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(post.userName)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .onTapGesture {
                        Task {
                            await getUserProfileToShow()
                        }
                        showUserProfile.toggle()
                    }
                Text(post.publishedDate.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.gray)
                Group {
                    if verifyUrl(urlString: post.url) {
                        Link(post.title, destination: URL(string: post.url)!)
                    } else {
                        Text(post.title)
                    }
                }
                .textSelection(.enabled)
                .padding(.vertical, 8)
                
                // MARK: Post Image If Any
                if let postImageURL = post.imageURL {
                    GeometryReader {
                        let size = $0.size
                        WebImage(url: postImageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.width, height: size.height)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .frame(height: 200)
                }
                
                if !post.text.isEmpty{
                    Text(post.text)
                        .font(.footnote)
                }
                
                PostInteraction()
            }
        }
        .hAlign(.leading)
        .overlay(alignment: .topTrailing, content: {
            // MARK: Displaying Delete Button (if it's Author of that post)
            if post.userUID == userUID {
                Menu {
                    Button("Delete Post", role: .destructive, action: deletePost)
                    Button(post.isReceived ? "Not received" : "Mark as received", action: changeReceiveStatus)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .rotationEffect(.init(degrees: -90))
                        .foregroundColor(.primary)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .offset(x: 8)
                
            } else {
                if post.isReceived {
                    Image(systemName: "checkmark.square.fill")
                        .offset(x: 8)
                }
                
            }
        })
        .onAppear {
            // MARK: Adding Only Once
            if docListener == nil { // when the post is visible on the screen, the document listener is added: otherwise, the listener is removed. Since we used LazyVStack earlier, onAppear() and onDisappear() will be called when the view enters or leaves the screen, respectively
                guard let postID = post.id else { return }
                docListener = Firestore.firestore().collection("Posts").document(postID).addSnapshotListener({ snapshot, error in
                    if let snapshot {
                        if snapshot.exists {
                            // MARK: Document Updated, Fetching Updated Document
                            if let updatedPost = try? snapshot.data(as: Post.self) {
                                onUpdate(updatedPost)
                            }
                            
                        } else {
                            // MARK: Document Deleted
                            onDelete()
                        }
                    }
                })
            }
        }
        .onDisappear { // as live updates are only provided when the post is shown on the screen, we can lower the cost of the document reads
            // MARK: Applying Snapshot Listener Only When the Post is Available on the Screen. Else Removing the Listener (it saves unwanted live updates from the posts which were swiped away from the screen)
            if let docListener {
                docListener.remove()
                self.docListener = nil
            }
        }
        .navigationDestination(isPresented: $showUserProfile) {
            if let userProfileToShow {
                ReusableProfileContent(user: userProfileToShow)
            }
        }
    }
    // MARK: Like/Dislike Interaction
    @ViewBuilder
    func PostInteraction() -> some View {
        HStack(spacing: 6) {
            Button(action: likePost) {
                Image(systemName: post.likedIDs.contains(userUID) ? "hand.thumbsup.fill" : "hand.thumbsup") // whenever it's either liked or disliked, we will add the user's UID to the post's liked/disliked array, and if the array contains the user's UID, then we will highlight the thumb to indicate that it's already been liked or disliked
            }
            
            Text("\(post.likedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            Button(action: dislikePost) {
                Image(systemName: post.dislikedIDs.contains(userUID) ? "hand.thumbsdown.fill" : "hand.thumbsdown")
            }
            .padding(.leading, 25)
            
            Text("\(post.dislikedIDs.count)")
                .font(.caption)
                .foregroundColor(.gray)
            
            if post.userUID != userUID {
                Button(action: copyPost) {
                    Image(systemName: "bookmark.circle.fill")
                }
            }
            
            Spacer()
            
            Label("\(post.seenCount)", systemImage: "eye")
                .onAppear {
                    seePost()
                }
        }
        .foregroundColor(.primary)
        .padding(.vertical, 8)
    }
    
    // MARK: Liking Post
    func likePost() {
        Task {
            guard let postID = post.id else { return }
            if post.likedIDs.contains(userUID) { // remove the user's UID from the relevant array if the post has already received likes: if not, add the user's UID to the array. For example, if a user liked the post before disliking it, the UID must be moved from the liked array list to the disliked array list
                // MARK: Removing User ID From the Array
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID])
                ])
            } else {
                // MARK: Adding User ID To Liked Array and Removing our ID from Disliked Array (if Added in prior)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayUnion([userUID]),
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            }
        }
    }
    
    // MARK: Disliking Post
    func dislikePost() {
        Task {
            guard let postID = post.id else { return }
            if post.dislikedIDs.contains(userUID) {
                // MARK: Removing User ID From the Array
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "dislikedIDs": FieldValue.arrayRemove([userUID])
                ])
            } else {
                // MARK: Adding User ID To Liked Array and Removing our ID from Disliked Array (if Added in prior)
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "likedIDs": FieldValue.arrayRemove([userUID]),
                    "dislikedIDs": FieldValue.arrayUnion([userUID])
                ])
            }
        }
    }
    
    func copyPost() {
        copyingPost.createNewPost = true
        copyingPost.postToCopy = post
    }
    
    func seePost() {
        Task {
            guard let postID = post.id else { return }
            if !post.seenIDs.contains(userUID) {
                try await Firestore.firestore().collection("Posts").document(postID).updateData([
                    "seenCount": post.seenCount + 1,
                    "seenIDs": FieldValue.arrayUnion([userUID])
                ])
            }
        }
    }
    
    // MARK: Deleting Post
    func deletePost() {
        Task {
            // Step 1: Delete Image from Firebase Storage if present.
            do {
                if !post.imageReferenceID.isEmpty {
                    try await Storage.storage().reference().child("Post_Images").child(post.imageReferenceID).delete()
                }
                // Step 2: Delete Firestore Document.
                guard let postID = post.id else { return }
                try await Firestore.firestore().collection("Posts").document(postID).delete()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func changeReceiveStatus() {
        Task {
            do {
                guard let postID = post.id else { return }
                try await Firestore.firestore().collection("Posts").document(postID).updateData(["isReceived": !post.isReceived])
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func getUserProfileToShow() async {
        guard let user = try? await Firestore.firestore().collection("Users").document(post.userUID).getDocument(as: User.self) else { return }
        userProfileToShow = user
    }
    
    func verifyUrl (urlString: String) -> Bool {
        if let url = URL(string: urlString) {
            return UIApplication.shared.canOpenURL(url as URL)
        }
        
        return false
    }
}

class CopyingPost: ObservableObject {
    @Published var createNewPost: Bool = false
    @Published var postToCopy: Post?
}
