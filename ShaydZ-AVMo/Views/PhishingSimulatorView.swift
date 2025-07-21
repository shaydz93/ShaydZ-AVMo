import SwiftUI
import WebKit

struct PhishingSimulatorView: View {
    @EnvironmentObject var securityToolkit: SecurityToolkitViewModel
    @State private var selectedTemplate: PhishingTemplate?
    @State private var showPreview = false
    @State private var customTitle = ""
    @State private var customBody = ""
    @State private var customTarget = ""
    @State private var createMode = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Phishing Simulator")
                    .font(.largeTitle)
                    .bold()
                
                Text("Create and preview phishing templates for security awareness training")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Template selection
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Available Templates")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            createMode = !createMode
                        }) {
                            Text(createMode ? "Cancel" : "Create New")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if createMode {
                        // Template creation form
                        TemplateCreationForm(
                            title: $customTitle,
                            body: $customBody,
                            target: $customTarget,
                            onSave: {
                                let newTemplate = PhishingTemplate(
                                    id: UUID(),
                                    name: customTitle,
                                    description: customBody.prefix(50) + "...",
                                    targetPlatform: customTarget,
                                    htmlContent: """
                                    <!DOCTYPE html>
                                    <html>
                                    <head>
                                        <title>\(customTitle)</title>
                                        <style>
                                            body { font-family: Arial, sans-serif; margin: 20px; }
                                            .container { max-width: 600px; margin: 0 auto; }
                                            .header { background-color: #0078D4; color: white; padding: 20px; }
                                            .content { padding: 20px; border: 1px solid #ddd; }
                                            .button { background-color: #0078D4; color: white; padding: 10px 20px; 
                                                     text-decoration: none; display: inline-block; margin-top: 20px; }
                                        </style>
                                    </head>
                                    <body>
                                        <div class="container">
                                            <div class="header">
                                                <h2>\(customTitle)</h2>
                                            </div>
                                            <div class="content">
                                                <p>\(customBody)</p>
                                                <a href="#" class="button">Take Action Now</a>
                                            </div>
                                        </div>
                                    </body>
                                    </html>
                                    """
                                )
                                
                                // Add to templates list
                                securityToolkit.phishingTemplates.insert(newTemplate, at: 0)
                                
                                // Reset form
                                customTitle = ""
                                customBody = ""
                                customTarget = ""
                                createMode = false
                            }
                        )
                    } else {
                        // Template list
                        ForEach(securityToolkit.phishingTemplates) { template in
                            PhishingTemplateCard(template: template)
                                .onTapGesture {
                                    selectedTemplate = template
                                }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Selected template preview
                if let template = selectedTemplate {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Template Details")
                            .font(.headline)
                        
                        HStack {
                            Text("Name:")
                                .fontWeight(.semibold)
                            Text(template.name)
                        }
                        
                        HStack {
                            Text("Target:")
                                .fontWeight(.semibold)
                            Text(template.targetPlatform)
                        }
                        
                        Text("Description:")
                            .fontWeight(.semibold)
                        Text(template.description)
                            .padding(.bottom, 5)
                        
                        Button(action: {
                            showPreview = true
                        }) {
                            Text("Preview Template")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        Text("Note: This simulator is for educational purposes only. Always use responsible disclosure practices and obtain proper authorization before conducting any security testing.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 5)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding()
            .sheet(isPresented: $showPreview) {
                if let template = selectedTemplate {
                    NavigationView {
                        PhishingPreviewView(htmlContent: template.htmlContent)
                            .navigationTitle("Template Preview")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("Close") {
                                        showPreview = false
                                    }
                                }
                            }
                    }
                }
            }
        }
    }
}

struct PhishingTemplateCard: View {
    let template: PhishingTemplate
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(template.name)
                .font(.headline)
            
            Text(template.targetPlatform)
                .font(.subheadline)
                .padding(4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
            
            Text(template.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.top, 2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .padding(.vertical, 5)
    }
}

struct TemplateCreationForm: View {
    @Binding var title: String
    @Binding var body: String
    @Binding var target: String
    var onSave: () -> Void
    
    var formIsValid: Bool {
        return !title.isEmpty && !body.isEmpty && !target.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Create New Template")
                .font(.headline)
            
            TextField("Template Name", text: $title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Target Platform", text: $target)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text("Template Content")
                .font(.subheadline)
            
            TextEditor(text: $body)
                .frame(minHeight: 150)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                )
            
            Button(action: onSave) {
                Text("Save Template")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(formIsValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(!formIsValid)
        }
    }
}

struct PhishingPreviewView: View {
    let htmlContent: String
    
    var body: some View {
        WebView(htmlContent: htmlContent)
            .overlay(
                VStack {
                    Spacer()
                    
                    Text("SIMULATION - For Educational Purposes Only")
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(5)
                        .padding(.bottom, 20)
                }
            )
    }
}

struct WebView: UIViewRepresentable {
    let htmlContent: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            // Prevent any actual navigation to external sites
            if navigationAction.navigationType == .linkActivated {
                decisionHandler(.cancel)
                return
            }
            
            decisionHandler(.allow)
        }
    }
}

struct PhishingSimulatorView_Previews: PreviewProvider {
    static var previews: some View {
        PhishingSimulatorView()
            .environmentObject(SecurityToolkitViewModel())
    }
}
