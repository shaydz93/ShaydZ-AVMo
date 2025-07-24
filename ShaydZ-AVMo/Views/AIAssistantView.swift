import SwiftUI

/// AI Assistant Chat Interface
struct AIAssistantView: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    @State private var messageText = ""
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isLoading {
                                TypingIndicatorView()
                                    .id("typing")
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(viewModel.messages.last?.id ?? "typing", anchor: .bottom)
                        }
                    }
                    .onChange(of: viewModel.isLoading) { isLoading in
                        if isLoading {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("typing", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Quick Suggestions
                if !viewModel.suggestions.isEmpty {
                    QuickSuggestionsView(
                        suggestions: viewModel.suggestions,
                        onSuggestionTapped: sendSuggestion
                    )
                }
                
                Divider()
                
                // Message Input
                MessageInputView(
                    messageText: $messageText,
                    isLoading: viewModel.isLoading,
                    onSend: sendMessage,
                    onVoiceInput: startVoiceInput
                )
                .focused($isMessageFieldFocused)
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear Chat", action: clearChat)
                        Button("View Analytics", action: viewAnalytics)
                        Button("Settings", action: openSettings)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadChatHistory()
            if viewModel.messages.isEmpty {
                viewModel.sendInitialGreeting()
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        messageText = ""
        isMessageFieldFocused = false
        
        viewModel.sendMessage(message)
    }
    
    private func sendSuggestion(_ suggestion: String) {
        messageText = suggestion
        sendMessage()
    }
    
    private func startVoiceInput() {
        // This would integrate with VoiceInputService
        viewModel.startVoiceInput()
    }
    
    private func clearChat() {
        viewModel.clearChat()
    }
    
    private func viewAnalytics() {
        // Navigate to analytics view
        print("View Analytics tapped")
    }
    
    private func openSettings() {
        // Navigate to AI settings
        print("Settings tapped")
    }
}

// MARK: - Chat Message View
struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    AIAvatarView()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.content)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(18)
                            
                            if !message.suggestions.isEmpty {
                                SuggestionChipsView(suggestions: message.suggestions) { suggestion in
                                    // Handle suggestion tap
                                }
                            }
                            
                            if !message.actionItems.isEmpty {
                                ActionItemsView(actionItems: message.actionItems)
                            }
                        }
                        
                        HStack {
                            Text(formatTime(message.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if let confidence = message.confidence {
                                Spacer()
                                ConfidenceIndicatorView(confidence: confidence)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 50)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - AI Avatar View
struct AIAvatarView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 32, height: 32)
            
            Image(systemName: "brain.head.profile")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack {
            AIAvatarView()
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .offset(y: animationOffset)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationOffset
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray5))
            .cornerRadius(18)
            
            Spacer()
        }
        .onAppear {
            animationOffset = -4
        }
    }
}

// MARK: - Quick Suggestions View
struct QuickSuggestionsView: View {
    let suggestions: [String]
    let onSuggestionTapped: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        onSuggestionTapped(suggestion)
                    }) {
                        Text(suggestion)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Message Input View
struct MessageInputView: View {
    @Binding var messageText: String
    let isLoading: Bool
    let onSend: () -> Void
    let onVoiceInput: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Voice Input Button
            Button(action: onVoiceInput) {
                Image(systemName: "mic.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
            }
            
            // Text Input
            HStack {
                TextField("Ask me anything...", text: $messageText, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .lineLimit(1...4)
                    .onSubmit {
                        onSend()
                    }
                
                if !messageText.isEmpty {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 24))
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(20)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Suggestion Chips View
struct SuggestionChipsView: View {
    let suggestions: [String]
    let onSuggestionTapped: (String) -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 6) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button(action: {
                    onSuggestionTapped(suggestion)
                }) {
                    Text(suggestion)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - Action Items View
struct ActionItemsView: View {
    let actionItems: [AIChatActionItem]
    
    var body: some View {
        VStack(spacing: 6) {
            ForEach(actionItems, id: \.action) { item in
                Button(action: {
                    handleActionItem(item)
                }) {
                    HStack {
                        Image(systemName: getActionIcon(for: item.type))
                        Text(item.label)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func getActionIcon(for type: String) -> String {
        switch type {
        case "view_recommendations":
            return "star.fill"
        case "view_vm_dashboard":
            return "gauge"
        case "run_diagnostic":
            return "stethoscope"
        case "navigation":
            return "arrow.right.circle"
        default:
            return "link"
        }
    }
    
    private func handleActionItem(_ item: AIChatActionItem) {
        // Handle different action types
        print("Action tapped: \(item.action)")
    }
}

// MARK: - Confidence Indicator View
struct ConfidenceIndicatorView: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < Int(confidence * 5) ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 4, height: 4)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    AIAssistantView()
}