import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ACCOUNT")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(viewModel.userName)
                                .font(.headline)
                            Text(viewModel.userEmail)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    NavigationLink(destination: ProfileSettingsView()) {
                        Text("Profile Settings")
                    }
                    
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        Text("Sign Out")
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("CONNECTION")) {
                    Toggle("Remember Last Server", isOn: $viewModel.rememberLastServer)
                    
                    Picker("Connection Quality", selection: $viewModel.selectedConnectionQuality) {
                        ForEach(ConnectionQuality.allCases, id: \.self) { quality in
                            Text(quality.rawValue).tag(quality)
                        }
                    }
                    
                    Toggle("Optimize for Battery", isOn: $viewModel.optimizeForBattery)
                    
                    HStack {
                        Text("Server Address")
                        Spacer()
                        Text(viewModel.serverAddress)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("SECURITY")) {
                    Toggle("Biometric Authentication", isOn: $viewModel.useBiometricAuth)
                    
                    NavigationLink(destination: Text("Password Change Screen")) {
                        Text("Change Password")
                    }
                    
                    Picker("Session Timeout", selection: $viewModel.sessionTimeout) {
                        ForEach(SessionTimeout.allCases, id: \.self) { timeout in
                            Text(timeout.displayName).tag(timeout)
                        }
                    }
                    
                    Toggle("Allow Copy/Paste Between Environments", isOn: $viewModel.allowCopyPasteBetweenEnvs)
                }
                
                Section(header: Text("ABOUT")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.appVersion)
                            .foregroundColor(.gray)
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy Screen")) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: Text("Terms of Service Screen")) {
                        Text("Terms of Service")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showingLogoutAlert) {
                Alert(
                    title: Text("Sign Out"),
                    message: Text("Are you sure you want to sign out?"),
                    primaryButton: .destructive(Text("Sign Out")) {
                        viewModel.signOut()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct ProfileSettingsView: View {
    @State private var name = "Demo User"
    @State private var email = "demo@example.com"
    
    var body: some View {
        Form {
            Section(header: Text("PERSONAL INFO")) {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            
            Section {
                Button("Save Changes") {
                    // Save changes logic
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
        }
        .navigationTitle("Profile Settings")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
