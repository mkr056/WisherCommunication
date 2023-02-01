//
//  EditProfileView.swift
//  Wisher
//
//  Created by Artem Mkr on 26.01.2023.
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import FirebaseFirestore

import SDWebImageSwiftUI

struct EditProfileView: View {
    
    // MARK: User Details
    @Binding var user: User! // the user to be modified
    @State private var userProfilePicData: Data? // for user profile picture
    @State private var userName: String = "" // for username TextField
    @State private var userBio: String = "" // for user bio TextField
    @State private var userBioLink: String = "" // for user bio link TextField
    
    // MARK: View Properties
    @State private var showImagePicker: Bool = false // for triggering photo gallery as a sheet
    @State private var photoItem: PhotosPickerItem? // for storing the selected image
    @State private var showError: Bool = false // for triggering an error alert
    @State private var errorMessage: String = "" // for storing error message in the alert
    @State private var isLoading: Bool = false // for triggering Loading View
    @Binding var shouldRefresh: Bool // // determines whether profile view has to be refreshed due to changes made to the user data
    @Environment(\.dismiss) var dismiss // for switching back to profile view
    
    // MARK: UserDefaults
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
        
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                if userProfilePicData == nil && user != nil { // this is used only once to show to current profile image
                    WebImage(url: user.userProfileURL).placeholder {
                        // MARK: Placeholder Image
                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    
                } else {
                    if let userProfilePicData, let image = UIImage(data: userProfilePicData) { // showing images selected from the gallery
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                    } else {
                        Image(systemName: "person.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top, 25)
            
            
            
            TextField("Username", text: $userName)
                .textContentType(.username)
                .border(1, .gray.opacity(0.5))
                .padding(.horizontal)
            
            
            
            TextField("About You", text: $userBio, axis: .vertical) // axis determines whether the text extends vertically or horizontally when does not fit on one like
                .frame(minHeight: 100, alignment: .top)
                .border(1, .gray.opacity(0.5))
                .padding(.horizontal)
            
            
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.URL)
                .border(1, .gray.opacity(0.5))
                .padding(.horizontal)
            
            
            
            Button(action: updateUser) {
                // MARK: Login Button
                Text("Save")
                    .foregroundColor(.primary)
                    .hAlign(.center)
                    .fillView(.secondary)
                    .padding(.horizontal)
                
            }
            .padding(.top, 10)
            Spacer()
        }
        .overlay(content: {
            LoadingView(show: $isLoading)
                .frame(maxWidth: .infinity)
            
        })
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { newValue in
            // MARK: Extracting UIImage From PhotoItem type
            if let newValue {
                Task {
                    do {
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else { return }
                        // MARK: UI Must Be Updated on Main Thread
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                            
                        })
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
        .onAppear { // populate textfields with initial user data
            shouldRefresh = false
            userName = user.username
            userBio = user.userBio
            userBioLink = user.userBioLink
        }
    }
    
    func updateUser() { // the main function for saving changes
        Task {
            isLoading = true // show the loading screen
            
            do {
                if userProfilePicData != nil { // if any image was selected from the gallery upload it to firestore storage
                    await updateProfileImage()
                }
                
                // changing user property values with values entered to the textfield
                user.username = userName
                user.userBio = userBio
                user.userBioLink = userBioLink
                
                // uploading new user to firestore
                let _ = try Firestore.firestore().collection("Users").document(user.userUID).setData(from: user, completion: { error in
                    if error == nil {
                        // MARK: Print Saved Successfully
                        print("Saved Successfully")

                        // Updating user defaults
                        userNameStored = userName
                        self.userUID = userUID
                        profileURL = user.userProfileURL
                        
                        Task {
                            await updatePostsRelatedToUser() // update posts shown in the profile view
                        }
                        
                        isLoading = false
                        dismiss()
                        shouldRefresh = true
                    }
                })

                
            } catch {
                print(error.localizedDescription)
            }
        }
        
        
        
    }
    
    func updateProfileImage() async {
        do {
            let storageRef = Storage.storage().reference().child("Profile_Images").child(user.userUID)
            let _ = try await storageRef.putDataAsync(userProfilePicData!)
            let downloadURL = try await storageRef.downloadURL()
            user.userProfileURL = downloadURL
        } catch {
            print("error")
        }
    }
    
    func updatePostsRelatedToUser() async {
        Firestore.firestore().collection("Posts").whereField("userUID", isEqualTo: user.userUID) // find all the posts created by the current user
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        Task {
                            try await Firestore.firestore().collection("Posts").document(document.documentID).updateData(
                                ["userName": userName, "userProfileURL" : "\(profileURL!)"] // update username and userProfileURL properties with new values for each post
                            )
                        }
                    }
                }
        }
    }
}


