//
//  LoginView.swift
//  JubileeMobileBay
//
//  Sign in with Apple login view
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    init(authenticationService: AuthenticationService) {
        _viewModel = StateObject(wrappedValue: AuthenticationViewModel(authenticationService: authenticationService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.cyan.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // App logo and title
                    VStack(spacing: 20) {
                        Image(systemName: "water.waves")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Jubilee Mobile Bay")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Track and share jubilee events")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 40)
                    
                    // Sign in section
                    VStack(spacing: 16) {
                        Text("Join the Community")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Sign in to report sightings and connect with other jubilee spotters")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Sign in with Apple button
                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                viewModel.handleSignInWithAppleRequest(request)
                            },
                            onCompletion: { result in
                                Task {
                                    await viewModel.handleSignInWithAppleCompletion(result)
                                }
                            }
                        )
                        .signInWithAppleButtonStyle(
                            colorScheme == .dark ? .white : .black
                        )
                        .frame(height: 50)
                        .padding(.horizontal, 40)
                        .disabled(viewModel.isAuthenticating)
                        .overlay {
                            if viewModel.isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Skip for now option
                    Button {
                        dismiss()
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 30)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Authentication Error", isPresented: viewModel.showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
            .task {
                // Check if already authenticated
                await viewModel.checkAuthentication()
            }
        }
    }
}

// MARK: - Login Prompt View

struct LoginPromptView: View {
    @Binding var showLogin: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Sign in Required")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Sign in with your Apple ID to access community features")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showLogin = true
            } label: {
                Label("Sign in with Apple", systemImage: "applelogo")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Authenticated User View

struct AuthenticatedUserView: View {
    let user: User
    let onSignOut: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.headline)
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            Button {
                Task {
                    await onSignOut()
                }
            } label: {
                Label("Sign Out", systemImage: "arrow.right.square")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Login View") {
    LoginView(authenticationService: AuthenticationService(cloudKitService: CloudKitService()))
}

#Preview("Login Prompt") {
    LoginPromptView(showLogin: .constant(false))
}

#Preview("Authenticated User") {
    AuthenticatedUserView(
        user: User(
            appleUserID: "123",
            email: "test@example.com",
            displayName: "Test User"
        ),
        onSignOut: {}
    )
}