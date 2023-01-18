//
//  RegisterView.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI // For Native SwiftUI Image Picker

// MARK: Building Register Page UI
struct RegisterView: View {
    
    // MARK: User Details
    @State private var userProfilePicData: Data? // for user profile picture
    @State private var userName: String = "" // for username TextField
    @State private var email: String = "" // for email TextField
    @State private var password: String = "" // for password TextField
    @State private var userBio: String = "" // for user bio TextField
    @State private var userBioLink: String = "" // for user bio link TextField
    
    // MARK: View Properties
    @Environment(\.dismiss) var dismiss // for switching back to login view
    @State private var showImagePicker: Bool = false // for triggering photo gallery as a sheet
    @State private var photoItem: PhotosPickerItem? // for storing the selected image
    @State private var showError: Bool = false // for triggering an error alert
    @State private var errorMessage: String = "" // for storing error message in the alert
    @State private var isLoading: Bool = false // for triggering Loading View
    
    // MARK: UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Register Account")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
//            Text("Hello user, have a wonderful journey")
//                .font(.title3)
//                .hAlign(.leading)
            
            // MARK: For Smaller Size Optimization
            // Why ViewThatFits? Consider iPhone 8, which has a smaller screen size in comparison with iPhone 14, so the view will be oversized and not usable on iPhone 8, and by using ViewThatFits, it will automatically enable scrollview if the content exceeds more that the available space.
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false) {
                    HelperView()
                }
                
                HelperView()
            }
            
            
            // MARK: Login Button
            HStack {
                Text("Already Have an account?")
                    .foregroundColor(.gray)
                Button("Login Now") {
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.primary)
            }
            .font(.callout)
            .vAlign(.bottom)
            
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
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
                        
                    }
                }
            }
        }
        
        // MARK: Displaying Alert
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    @ViewBuilder
    func HelperView() -> some View {
        VStack(spacing: 12) {
            
            ZStack {
                if let userProfilePicData, let image = UIImage(data: userProfilePicData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    
                } else {
                    Image(systemName: "person.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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
            
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            
            SecureField("Password", text: $password)
                .textContentType(.password)
                .border(1, .gray.opacity(0.5))
            
            TextField("About You", text: $userBio, axis: .vertical) // axis determines whether the text extends vertically or horizontally when does not fit on one like
                .frame(minHeight: 100, alignment: .top)
                .border(1, .gray.opacity(0.5))
            
            TextField("Bio Link (Optional)", text: $userBioLink)
                .textContentType(.URL)
                .border(1, .gray.opacity(0.5))
            
            
            Button(action: registerUser) {
                // MARK: Login Button
                Text("Sign up")
                    .foregroundColor(.primary)
                    .hAlign(.center)
                    .fillView(.primary)
            }
            .disableWithOpacity(userName.isEmpty || userBio.isEmpty || email.isEmpty || password.isEmpty || userProfilePicData == nil)
            .padding(.top, 10)
        }
    }
    
    func registerUser() {
        closeKeyboard()
        isLoading = true
        Task {
            do {
                // Step 1: Creating Firebase Account.
                try await Auth.auth().createUser(withEmail: email, password: password)
                // Step 2: Uploading Profile Photo Into Firebase Storage.
                guard let userUID = Auth.auth().currentUser?.uid else { return }
                guard let imageData = userProfilePicData else { return }
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                // Step 3: Downloading Photo URL.
                let downloadURL = try await storageRef.downloadURL()
                // Step 4: Creating a User Firestore Object.
                let user = User(username: userName, userBio: userBio, userBioLink: userBioLink, userUID: userUID, userEmail: email, userProfileURL: downloadURL)
                // Step 5: Saving User Doc into Firestore Database.
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: { error in
                    if error == nil {
                        // MARK: Print Saved Successfully
                        print("Saved Successfully")
                        userNameStored = userName
                        self.userUID = userUID
                        profileURL = downloadURL
                        logStatus = true
                    }
                })
                
                
            } catch {
                await setError(error)
            }
        }
    }
    
    // MARK: Displaying Errors VIA Alert
    func setError(_ error: Error) async {
        // MARK: UI Must be Updated on Main Thread
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()

        })
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
