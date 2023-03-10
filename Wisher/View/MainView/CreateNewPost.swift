//
//  CreateNewPost.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage

struct CreateNewPost: View {
    var copyingPost: Bool = false
    var postToCopy: Post?
    /// - Callbacks
    var onPost: (Post) -> ()
    
    /// - Post Properties
    @State private var postTitle: String = "" // for post title TextField
    @State private var postURL: String = "" // for post title TextField
    @State private var postText: String = "" // for post content TextField
    @State private var postImageData: Data? // for post image
    
    /// - Stored User Data From UserDefaults(AppStorage)
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName: String = ""
    @AppStorage("user_UID") private var userUID: String = ""
    
    /// - View Properties
    @Environment(\.dismiss) private var dismiss // dismiss current sheet after clicking cancel or post buttons
    @State private var isLoading: Bool = false // for triggering Loading View
    @State private var showError: Bool = false // for triggering an error alert
    @State private var errorMessage: String = "" // for storing error message in the alert
    @State private var showImagePicker: Bool = false // for triggering photo gallery as a sheet
    @State private var photoItem: PhotosPickerItem? // for storing the selected image
    @FocusState private var showTitleKeyboard: Bool // for hiding the keyboard when post or done buttons are clicked
    @FocusState private var showURLKeyboard: Bool // for hiding the keyboard when post or done buttons are clicked
    @FocusState private var showTextKeyboard: Bool // for hiding the keyboard when post or done buttons are clicked
    
    var body: some View {
        VStack {
            HStack {
                Menu {
                    Button("Cancel", role: .destructive) {
                        dismiss()
                    }
                } label: {
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.primary)
                }
                .hAlign(.leading)
                
                Button(action: createPost) {
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 6)
                        .background(.secondary, in: Capsule())
                }
                .disableWithOpacity(postTitle.isEmpty)
                
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background {
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
            }
            VStack {
                Group {
                    TextField("Wish title", text: $postTitle)
                        .focused($showTitleKeyboard)
                    TextField("URL (optional)", text: $postURL)
                        .focused($showURLKeyboard)
                }
                .padding(.bottom, 10)
                .padding(.horizontal)
            }
            Divider()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    TextField("What's happening?", text: $postText, axis: .vertical)
                        .focused($showTextKeyboard)
                    if let postImageData, let image = UIImage(data: postImageData) {
                        GeometryReader {
                            let size = $0.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            /// - Delete Button
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.25)) {
                                            self.postImageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }
                                    .padding(10)
                                    
                                }
                        }
                        .clipped()
                        .frame(height: 220)
                        // zIndex fixes the bug of geometry reader getting on top of the textfield when the image is added before typing the title
                        .zIndex(-1)
                    }
                    
                }
                .padding(15)
            }
            
            Divider()
            HStack {
                Button {
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                }
                .hAlign(.leading)
                
                Button("Done") {
                    hideAllKeyboards()
                }

            }
            .foregroundColor(.primary)
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
        }
        .onAppear {

            if copyingPost {
                guard postToCopy != nil else {
                    dismiss()
                    return
                }
                populateDataForPostToCopy()
            }
            showTitleKeyboard = true
        }
        .vAlign(.top)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { newValue in
            if let newValue {
                Task {
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self), let image = UIImage(data: rawImageData), let compressedImageData = image.jpegData(compressionQuality: 0.5) { // compressing images so that we can save storage space. Compression is purely your idea: you can also choose to upload the raw image as well
                        /// - UI Must be done on Main Thread
                        await MainActor.run(body: {
                            postImageData = compressedImageData
                            photoItem = nil
                        })
                    }
                    
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
        /// - Loading View
        .overlay {
            LoadingView(show: $isLoading)
        }
    }
    
    func populateDataForPostToCopy() {
        guard let post = postToCopy else { return }
        postTitle = post.title
        postURL = post.url
        postText = post.text
        Task {
            if let imageURL = post.imageURL { // if post to copy contains an image, fetch it
                setDataFromURL(url: imageURL)
            }
        }
    }
    
    func setDataFromURL(url: URL) {
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            // Error handling...
            guard let imageData = data else { return }
            
            DispatchQueue.main.async {
                postImageData = imageData
            }
        }.resume()
    }
    
    func hideAllKeyboards() {
        showTitleKeyboard = false
        showURLKeyboard = false
        showTextKeyboard = false
    }
    
    // MARK: Post Content To Firebase
    func createPost() {
        isLoading = true
        hideAllKeyboards()
        
        Task {
            do {
                guard let profileURL = profileURL else { return }
                // Step 1: Uploading Image If any.
                // Used to delete the Post
                let imageReferenceID = "\(userUID)\(Date())"
                let storageReference = Storage.storage().reference().child("Post_Images").child(imageReferenceID)
                if let postImageData {
                    let _ = try await storageReference.putDataAsync(postImageData)
                    let downloadURL = try await storageReference.downloadURL()
                    
                    // Step 3: Create Post Object With Image Id and URL.
                    let post = Post(title: postTitle, url: postURL, text: postText, imageURL: downloadURL, imageReferenceID: imageReferenceID, userName: userName, userUID: userUID, userProfileURL: profileURL)
                    try await createDocumentAtFirebase(post)
                } else {
                    // Step 2: Directly Post Text Data to Firebase (Since there is no Images Present).
                    let post = Post(title: postTitle, url: postURL, text: postText, userName: userName, userUID: userUID, userProfileURL: profileURL)
                    try await createDocumentAtFirebase(post)
                }
            } catch {
                await setError(error)
            }
        }
    }
    
    func createDocumentAtFirebase(_ post: Post) async throws {
        /// - Writing Document to Firebase Firestore
        let doc = Firestore.firestore().collection("Posts").document()
        let _ = try doc.setData(from: post, completion: { error in
            if error == nil {
                /// Post Successfully Stored at Firebase
                isLoading = false
                var updatedPost = post
                updatedPost.id = doc.documentID
                onPost(updatedPost)
                dismiss()
            }
        })
    }
    
    // MARK: Displaying Errors as Alert
    func setError(_ error: Error) async {
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}

struct CreateNewPost_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewPost { _ in }
    }
}
