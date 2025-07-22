import SwiftUI

/// Loading overlay extension for views
extension View {
    /// Adds a loading overlay to any view
    public func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text(message)
                                .foregroundColor(.white)
                                .font(.body)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.8))
                        )
                    }
                }
            }
        )
    }
}

/// Error alert extension for views
extension View {
    /// Adds an error alert to any view
    public func errorAlert(
        errorMessage: Binding<String?>,
        title: String = "Error"
    ) -> some View {
        self.alert(title, isPresented: .constant(errorMessage.wrappedValue != nil)) {
            Button("OK") {
                errorMessage.wrappedValue = nil
            }
        } message: {
            if let message = errorMessage.wrappedValue {
                Text(message)
            }
        }
    }
}

/// VM Status color extension
extension ShaydZAVMo_VMStatus {
    public var statusColor: Color {
        switch self {
        case .running:
            return .green
        case .starting, .resuming:
            return .orange
        case .stopped:
            return .gray
        case .paused:
            return .yellow
        case .pausing, .stopping:
            return .orange
        case .error:
            return .red
        case .unknown:
            return .purple
        }
    }
    
    public var statusIcon: String {
        switch self {
        case .running:
            return "play.circle.fill"
        case .starting, .resuming:
            return "play.circle"
        case .stopped:
            return "stop.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .pausing, .stopping:
            return "stop.circle"
        case .error:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}

/// App model icon extension
extension ShaydZAVMo_AppModel {
    public var systemIcon: String {
        switch category.lowercased() {
        case "browsers":
            return "globe"
        case "communication":
            return "message.circle"
        case "social":
            return "person.2.circle"
        case "music":
            return "music.note.circle"
        case "productivity":
            return "doc.text.circle"
        case "games":
            return "gamecontroller.circle"
        case "utilities":
            return "wrench.and.screwdriver.circle"
        case "entertainment":
            return "tv.circle"
        default:
            return "app.circle"
        }
    }
    
    public var installationStatusColor: Color {
        if isInstalled {
            return .green
        } else if canInstall {
            return .blue
        } else {
            return .gray
        }
    }
}

/// Date formatting extension
extension Date {
    public var timeAgoDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    public var shortDateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

/// String validation extensions
extension String {
    public var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: self)
    }
    
    public var isValidPassword: Bool {
        return count >= 6
    }
    
    public var isValidUsername: Bool {
        return count >= 3 && allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }
}
