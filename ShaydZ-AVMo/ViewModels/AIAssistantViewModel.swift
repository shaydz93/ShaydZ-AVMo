import Foundation
import Combine
import SwiftUI

/// ViewModel for AI Assistant Chat Interface
@MainActor
class AIAssistantViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var suggestions: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let aiService = AIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupInitialSuggestions()
    }
    
    // MARK: - Public Methods
    
    /// Load chat history from backend
    func loadChatHistory() {
        aiService.getChatHistory(limit: 50)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to load chat history: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    self?.processHistoryResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Send initial greeting message
    func sendInitialGreeting() {
        let greeting = ChatMessage(
            id: UUID().uuidString,
            content: "Hello! I'm your ShaydZ AVMo AI Assistant. I can help you with app recommendations, VM management, troubleshooting, and more. What would you like to know?",
            isFromUser: false,
            timestamp: Date(),
            intent: "greeting",
            confidence: 1.0,
            suggestions: [
                "Recommend apps for productivity",
                "Help with VM performance",
                "Troubleshoot connection issues"
            ],
            actionItems: []
        )
        
        messages.append(greeting)
        updateSuggestions(greeting.suggestions)
    }
    
    /// Send message to AI assistant
    func sendMessage(_ message: String) {
        // Add user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            content: message,
            isFromUser: true,
            timestamp: Date(),
            intent: nil,
            confidence: nil,
            suggestions: [],
            actionItems: []
        )
        
        messages.append(userMessage)
        clearSuggestions()
        
        // Send to AI service
        isLoading = true
        errorMessage = nil
        
        let context = buildContext()
        
        aiService.sendChatMessage(message, context: context)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleChatError(error)
                    }
                },
                receiveValue: { [weak self] response in
                    self?.processAIResponse(response)
                }
            )
            .store(in: &cancellables)
        
        // Track AI feature usage
        aiService.trackFeatureUsage("ai_chat", metadata: ["message_length": message.count])
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    /// Start voice input (placeholder for VoiceInputService integration)
    func startVoiceInput() {
        // This would integrate with VoiceInputService
        print("Voice input started")
        // For now, simulate voice input with a predefined message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendMessage("How can I optimize my VM performance?")
        }
    }
    
    /// Clear chat history
    func clearChat() {
        messages.removeAll()
        setupInitialSuggestions()
        
        aiService.clearChatHistory()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to clear chat history: \(error.localizedDescription)")
                    }
                },
                receiveValue: { _ in
                    print("Chat history cleared")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func processHistoryResponse(_ response: AIChatHistoryResponse) {
        let historyMessages = response.data.history.flatMap { historyItem -> [ChatMessage] in
            let userMessage = ChatMessage(
                id: UUID().uuidString,
                content: historyItem.userMessage,
                isFromUser: true,
                timestamp: parseDate(historyItem.timestamp),
                intent: nil,
                confidence: nil,
                suggestions: [],
                actionItems: []
            )
            
            let aiMessage = ChatMessage(
                id: UUID().uuidString,
                content: historyItem.aiResponse,
                isFromUser: false,
                timestamp: parseDate(historyItem.timestamp),
                intent: nil,
                confidence: nil,
                suggestions: [],
                actionItems: []
            )
            
            return [userMessage, aiMessage]
        }
        
        messages = historyMessages
    }
    
    private func processAIResponse(_ response: AIChatResponse) {
        let aiMessage = ChatMessage(
            id: UUID().uuidString,
            content: response.data.response,
            isFromUser: false,
            timestamp: parseDate(response.data.timestamp),
            intent: response.data.intent,
            confidence: response.data.confidence,
            suggestions: response.data.suggestions,
            actionItems: response.data.actionItems
        )
        
        messages.append(aiMessage)
        updateSuggestions(response.data.suggestions)
        isLoading = false
    }
    
    private func handleChatError(_ error: APIError) {
        errorMessage = "Failed to send message: \(error.localizedDescription)"
        
        // Add error message to chat
        let errorMessage = ChatMessage(
            id: UUID().uuidString,
            content: "I apologize, but I'm experiencing some technical difficulties. Please try again later.",
            isFromUser: false,
            timestamp: Date(),
            intent: "error",
            confidence: 1.0,
            suggestions: ["Try again", "Check connection", "Contact support"],
            actionItems: []
        )
        
        messages.append(errorMessage)
        updateSuggestions(errorMessage.suggestions)
    }
    
    private func buildContext() -> [String: Any] {
        // Build context from recent messages and app state
        let recentMessages = Array(messages.suffix(5))
        return [
            "recent_messages": recentMessages.count,
            "session_length": messages.count,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    private func updateSuggestions(_ newSuggestions: [String]) {
        suggestions = newSuggestions
    }
    
    private func clearSuggestions() {
        suggestions = []
    }
    
    private func setupInitialSuggestions() {
        suggestions = [
            "Recommend productivity apps",
            "Check my VM status",
            "What can you help me with?"
        ]
    }
    
    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let intent: String?
    let confidence: Double?
    let suggestions: [String]
    let actionItems: [AIChatActionItem]
}

// MARK: - Mock Data for Preview
extension AIAssistantViewModel {
    static func mock() -> AIAssistantViewModel {
        let viewModel = AIAssistantViewModel()
        viewModel.messages = [
            ChatMessage(
                id: "1",
                content: "Hello! I'm your ShaydZ AVMo AI Assistant. How can I help you today?",
                isFromUser: false,
                timestamp: Date().addingTimeInterval(-120),
                intent: "greeting",
                confidence: 1.0,
                suggestions: ["Recommend apps", "Check VM status", "Help with performance"],
                actionItems: []
            ),
            ChatMessage(
                id: "2",
                content: "Can you recommend some productivity apps?",
                isFromUser: true,
                timestamp: Date().addingTimeInterval(-60),
                intent: nil,
                confidence: nil,
                suggestions: [],
                actionItems: []
            ),
            ChatMessage(
                id: "3",
                content: "Based on your usage patterns, I recommend Virtual Office Suite for document editing and Team Collaboration for communication. Both are highly rated and match your productivity needs.",
                isFromUser: false,
                timestamp: Date(),
                intent: "app_recommendation",
                confidence: 0.85,
                suggestions: ["Show me more apps", "Install Office Suite", "View app details"],
                actionItems: [
                    AIChatActionItem(
                        type: "view_recommendations",
                        label: "View All Recommendations",
                        action: "navigate_to_recommendations"
                    )
                ]
            )
        ]
        viewModel.suggestions = ["Show me more apps", "Install Office Suite", "View app details"]
        return viewModel
    }
}