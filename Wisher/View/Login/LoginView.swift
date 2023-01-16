//
//  LoginView.swift
//  Wisher
//
//  Created by Artem Mkr on 15.01.2023.
//

import Firebase
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct LoginView: View {
    
    // MARK: User Details
    @State private var email: String = ""
    @State private var password: String = ""
    
    // MARK: View Properties
    @State private var createAccount: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    
    //MARK: UserDefaults
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    @AppStorage("log_status") var logStatus: Bool = false
    
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Sign in")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Welcome Back!")
                .font(.title3)
                .hAlign(.leading)
            
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top, 25)
                
                SecureField("Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                
                Button("Reset password?", action: resetPassword)
                    .font(.callout)
                    .fontWeight(.medium)
                    .tint(.primary)
                    .hAlign(.trailing)
                
                Button(action: loginUser) {
                    // MARK: Login Button
                    Text("Sign in")
                        .foregroundColor(.primary)
                        .hAlign(.center)
                        .fillView(.secondary)
                }
                .padding(.top, 10)
            }
            
            // MARK: Register Button
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.gray)
                Button("Register Now") {
                    createAccount.toggle()
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
        
        // MARK: Register View VIA Sheets
        .fullScreenCover(isPresented: $createAccount) {
            RegisterView()
        }
        
        // MARK: Displaying Alert
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    
    func loginUser() {
        isLoading = true
        closeKeyboard()
        Task {
            do {
                // With the help of Swift Concurrency Auth can be done with Single Line
                try await Auth.auth().signIn(withEmail: email, password: password)
                print("User Found")
                try await fetchUser()
            } catch {
                await setError(error)
            }
        }
    }
    
    // MARK: If User is Found then Fetching User Data From Firestore
    func fetchUser() async throws {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        // MARK: UI Updating Must be Run On Main Thread
        await MainActor.run(body: {
            // Setting UserDefaults data and Changing App's Auth Status
            userUID = userID
            userNameStored = user.username
            profileURL = user.userProfileURL
            logStatus = true
            
        })
    }
    
    func resetPassword() {
        Task {
            do {
                // With the help of Swift Concurrency Auth can be done with Single Line
                try await Auth.auth().sendPasswordReset(withEmail: email)
                print("Link Sent")
            } catch {
                await setError(error)
            }
        }
    }
    
    // MARK: Displaying Errors VIA Alert
    func setError(_ error: Error) async {
        // MARK: UI Must be Updated on Main Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}





struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
