import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color("PrimaryBackground")
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo and title
                VStack {
                    Image(systemName: "lock.shield.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("ShaydZ AVMo")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text("Secure Virtual Mobile Access")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Login form
                VStack(spacing: 20) {
                    TextField("Username", text: $username)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Button(action: authenticateUser) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        } else {
                            Text("Sign In")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                    
                    Button(action: {
                        // Implement forgot password functionality
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Additional information
                VStack {
                    Text("Secure Zero-Trust Mobile Access")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("© 2025 ShaydZ AVMo. All rights reserved.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)
            }
            .padding()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Authentication Failed"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func authenticateUser() {
        // Simulate authentication
        isLoading = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if username.lowercased() == "demo" && password == "password" {
                isAuthenticated = true
            } else {
                errorMessage = "Invalid username or password. Please try again."
                showingAlert = true
            }
            isLoading = false
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isAuthenticated: .constant(false))
    }
}
