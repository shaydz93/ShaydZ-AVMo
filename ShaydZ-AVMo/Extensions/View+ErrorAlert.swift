import SwiftUI

extension View {
    /// Shows an error alert when the binding to error is not nil
    /// After the alert is dismissed, the error will be set to nil
    func errorAlert(error: Binding<Error?>, buttonTitle: String = "OK") -> some View {
        let localizedError = error.wrappedValue as? LocalizedError
        return alert(
            isPresented: .constant(error.wrappedValue != nil),
            error: localizedError,
            actions: { _ in
                Button(buttonTitle) {
                    error.wrappedValue = nil
                }
            },
            message: { error in
                Text(error.recoverySuggestion ?? "")
            }
        )
    }
    
    /// Shows an error alert using a simple error message string
    func errorAlert(errorMessage: Binding<String?>, buttonTitle: String = "OK") -> some View {
        alert("Error", isPresented: .constant(errorMessage.wrappedValue != nil)) {
            Button(buttonTitle) {
                errorMessage.wrappedValue = nil
            }
        } message: {
            if let message = errorMessage.wrappedValue {
                Text(message)
            }
        }
    }
    
    /// Loading overlay for async operations
    func loadingOverlay(isLoading: Bool) -> some View {
        overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        )
                }
            }
        )
    }
    
    /// Shows an alert for an APIError when the binding to error is not nil
    /// After the alert is dismissed, the error will be set to nil
    func apiErrorAlert(error: Binding<APIError?>, buttonTitle: String = "OK") -> some View {
        return alert(
            isPresented: .constant(error.wrappedValue != nil),
            content: {
                let errorMessage = error.wrappedValue?.localizedDescription ?? "An unknown error occurred"
                return Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text(buttonTitle)) {
                        error.wrappedValue = nil
                    }
                )
            }
        )
    }
    
    /// Shows a loading overlay when isLoading is true
    func loadingOverlay(isLoading: Bool) -> some View {
        return self.overlay(
            Group {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                        
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
            }
        )
    }
}
