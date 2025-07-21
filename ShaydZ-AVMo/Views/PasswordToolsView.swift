import SwiftUI

struct PasswordToolsView: View {
    @EnvironmentObject var securityToolkit: SecurityToolkitViewModel
    @State private var password = ""
    @State private var passwordLength = 16.0
    @State private var includeLowercase = true
    @State private var includeUppercase = true
    @State private var includeNumbers = true
    @State private var includeSpecialChars = true
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var passwordAudit: PasswordAudit?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Password Tools")
                    .font(.largeTitle)
                    .bold()
                
                // Password Analyzer
                VStack(alignment: .leading, spacing: 10) {
                    Text("Password Strength Analyzer")
                        .font(.headline)
                    
                    Text("Check the strength of a password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    SecureField("Enter a password to analyze", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 5)
                    
                    Button(action: {
                        passwordAudit = securityToolkit.auditPassword(password)
                    }) {
                        Text("Analyze Password")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(password.isEmpty)
                    
                    if let audit = passwordAudit {
                        PasswordAuditView(audit: audit)
                            .padding(.top)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Password Generator
                VStack(alignment: .leading, spacing: 10) {
                    Text("Secure Password Generator")
                        .font(.headline)
                    
                    Text("Generate strong, random passwords")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading) {
                        Text("Password Length: \(Int(passwordLength))")
                        Slider(value: $passwordLength, in: 8...64, step: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Include Lowercase Letters (a-z)", isOn: $includeLowercase)
                        Toggle("Include Uppercase Letters (A-Z)", isOn: $includeUppercase)
                        Toggle("Include Numbers (0-9)", isOn: $includeNumbers)
                        Toggle("Include Special Characters (!@#$...)", isOn: $includeSpecialChars)
                    }
                    
                    Button(action: {
                        generatePassword()
                    }) {
                        Text("Generate Password")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(!includeLowercase && !includeUppercase && !includeNumbers && !includeSpecialChars)
                    
                    // Generated passwords list
                    if !securityToolkit.generatedPasswords.isEmpty {
                        Text("Generated Passwords")
                            .font(.headline)
                            .padding(.top)
                        
                        ForEach(securityToolkit.generatedPasswords, id: \.self) { generatedPassword in
                            HStack {
                                Text(generatedPassword)
                                    .font(.system(.body, design: .monospaced))
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .cornerRadius(5)
                                
                                Spacer()
                                
                                Button(action: {
                                    UIPasteboard.general.string = generatedPassword
                                    showToast = true
                                    toastMessage = "Password copied to clipboard"
                                    
                                    // Hide toast after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showToast = false
                                    }
                                }) {
                                    Image(systemName: "doc.on.doc")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
            .padding()
            .overlay(
                // Toast message
                ZStack {
                    if showToast {
                        VStack {
                            Spacer()
                            
                            Text(toastMessage)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.bottom, 20)
                                .transition(.move(edge: .bottom))
                        }
                    }
                }
            )
        }
    }
    
    private func generatePassword() {
        guard includeLowercase || includeUppercase || includeNumbers || includeSpecialChars else { return }
        
        let password = securityToolkit.generateSecurePassword(length: Int(passwordLength))
        
        // Add password to the list, keeping only the last 5
        var passwords = securityToolkit.generatedPasswords
        passwords.insert(password, at: 0)
        if passwords.count > 5 {
            passwords = Array(passwords.prefix(5))
        }
        securityToolkit.generatedPasswords = passwords
    }
}

struct PasswordAuditView: View {
    let audit: PasswordAudit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Strength:")
                    .font(.headline)
                
                Spacer()
                
                // Strength meter
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { index in
                        Rectangle()
                            .frame(width: 15, height: 8)
                            .foregroundColor(index <= audit.strength ? strengthColor(audit.strength) : Color.gray.opacity(0.3))
                            .cornerRadius(2)
                    }
                }
            }
            
            HStack {
                Text("Time to Break:")
                    .font(.headline)
                
                Spacer()
                
                Text(audit.timeToBreak)
                    .font(.body)
                    .foregroundColor(timeBreakColor(audit.timeToBreak))
            }
            
            if !audit.issues.isEmpty {
                Text("Issues:")
                    .font(.headline)
                    .padding(.top, 5)
                
                ForEach(audit.issues, id: \.self) { issue in
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        
                        Text(issue)
                            .font(.caption)
                    }
                }
            }
            
            if !audit.suggestions.isEmpty {
                Text("Suggestions:")
                    .font(.headline)
                    .padding(.top, 5)
                
                ForEach(audit.suggestions, id: \.self) { suggestion in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(suggestion)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
    
    private func strengthColor(_ strength: Int) -> Color {
        switch strength {
        case 0...1:
            return .red
        case 2:
            return .orange
        case 3:
            return .yellow
        case 4:
            return .green
        case 5:
            return .blue
        default:
            return .gray
        }
    }
    
    private func timeBreakColor(_ time: String) -> Color {
        switch time {
        case "Instantly", "Seconds", "Hours":
            return .red
        case "Days":
            return .orange
        case "Years":
            return .green
        case "Centuries":
            return .blue
        default:
            return .primary
        }
    }
}

struct PasswordToolsView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordToolsView()
            .environmentObject(SecurityToolkitViewModel())
    }
}
