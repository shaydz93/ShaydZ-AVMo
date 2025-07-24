const express = require('express');
const router = express.Router();

// AI Chat service with mock conversational intelligence
class AIAssistant {
  constructor(db) {
    this.db = db;
    this.conversationHistory = new Map();
  }

  // Process user message and generate AI response
  async processMessage(userId, message, context = {}) {
    try {
      // Get conversation history
      const history = this.conversationHistory.get(userId) || [];
      
      // Analyze intent and generate response
      const response = await this.generateResponse(message, history, context);
      
      // Update conversation history
      history.push(
        { role: 'user', content: message, timestamp: new Date() },
        { role: 'assistant', content: response.content, timestamp: new Date() }
      );
      
      // Keep only last 10 exchanges
      if (history.length > 20) {
        history.splice(0, history.length - 20);
      }
      
      this.conversationHistory.set(userId, history);
      
      // Store conversation in database
      await this.storeConversation(userId, message, response.content);
      
      return response;
    } catch (error) {
      console.error('Error processing message:', error);
      return {
        content: "I apologize, but I'm experiencing some technical difficulties. Please try again later.",
        intent: 'error',
        confidence: 1.0
      };
    }
  }

  // Generate AI response based on message analysis
  async generateResponse(message, history, context) {
    const intent = this.analyzeIntent(message);
    const lowerMessage = message.toLowerCase();
    
    switch (intent.type) {
      case 'app_recommendation':
        return this.generateAppRecommendationResponse(message, context);
      
      case 'vm_management':
        return this.generateVMManagementResponse(message, context);
      
      case 'troubleshooting':
        return this.generateTroubleshootingResponse(message, context);
      
      case 'greeting':
        return {
          content: "Hello! I'm your ShaydZ AVMo AI Assistant. I can help you with app recommendations, VM management, troubleshooting, and more. What would you like to know?",
          intent: intent.type,
          confidence: intent.confidence,
          suggestions: [
            "Recommend apps for productivity",
            "Help with VM performance",
            "Troubleshoot connection issues"
          ]
        };
      
      case 'help':
        return {
          content: "I can assist you with:\n\n• **App Recommendations** - Find the perfect apps for your needs\n• **VM Management** - Optimize your virtual machine performance\n• **Troubleshooting** - Resolve technical issues\n• **Performance Analytics** - Monitor and improve system efficiency\n\nJust ask me anything about your ShaydZ AVMo experience!",
          intent: intent.type,
          confidence: intent.confidence,
          suggestions: [
            "Show me popular productivity apps",
            "Why is my VM running slowly?",
            "How can I improve performance?"
          ]
        };
      
      default:
        return this.generateGeneralResponse(message, intent);
    }
  }

  // Analyze user message intent
  analyzeIntent(message) {
    const lowerMessage = message.toLowerCase();
    
    // App recommendation keywords
    if (lowerMessage.includes('recommend') || lowerMessage.includes('app') || 
        lowerMessage.includes('software') || lowerMessage.includes('install')) {
      return { type: 'app_recommendation', confidence: 0.8 };
    }
    
    // VM management keywords
    if (lowerMessage.includes('vm') || lowerMessage.includes('virtual machine') ||
        lowerMessage.includes('performance') || lowerMessage.includes('resource')) {
      return { type: 'vm_management', confidence: 0.8 };
    }
    
    // Troubleshooting keywords
    if (lowerMessage.includes('problem') || lowerMessage.includes('error') ||
        lowerMessage.includes('issue') || lowerMessage.includes('fix') ||
        lowerMessage.includes('broken') || lowerMessage.includes('not work')) {
      return { type: 'troubleshooting', confidence: 0.9 };
    }
    
    // Greeting keywords
    if (lowerMessage.includes('hello') || lowerMessage.includes('hi') ||
        lowerMessage.includes('hey') || lowerMessage.includes('start')) {
      return { type: 'greeting', confidence: 0.9 };
    }
    
    // Help keywords
    if (lowerMessage.includes('help') || lowerMessage.includes('what can you') ||
        lowerMessage.includes('how to') || lowerMessage.includes('guide')) {
      return { type: 'help', confidence: 0.9 };
    }
    
    return { type: 'general', confidence: 0.5 };
  }

  // Generate app recommendation response
  generateAppRecommendationResponse(message, context) {
    const recommendations = [
      "Based on your usage patterns, I recommend **Virtual Office Suite** for productivity and **Secure Browser** for safe web browsing.",
      "For development work, try **Development IDE** - it's highly rated by our users. Would you like me to show you more developer tools?",
      "I see you might enjoy **Media Player Pro** for entertainment and **Team Collaboration** for communication needs."
    ];
    
    return {
      content: recommendations[Math.floor(Math.random() * recommendations.length)],
      intent: 'app_recommendation',
      confidence: 0.8,
      suggestions: [
        "Show me productivity apps",
        "Find developer tools",
        "Browse entertainment apps"
      ],
      actionItems: [
        {
          type: 'view_recommendations',
          label: 'View All Recommendations',
          action: 'navigate_to_recommendations'
        }
      ]
    };
  }

  // Generate VM management response
  generateVMManagementResponse(message, context) {
    const responses = [
      "Your VM performance looks good! Current CPU usage is optimal. I can help optimize memory allocation if needed.",
      "I notice your VM could benefit from more RAM allocation. Would you like me to suggest optimal resource settings?",
      "VM performance can be improved by closing unused apps and optimizing background processes. Shall I guide you through this?"
    ];
    
    return {
      content: responses[Math.floor(Math.random() * responses.length)],
      intent: 'vm_management',
      confidence: 0.8,
      suggestions: [
        "Optimize VM resources",
        "Check VM status",
        "View performance metrics"
      ],
      actionItems: [
        {
          type: 'view_vm_dashboard',
          label: 'Open VM Dashboard',
          action: 'navigate_to_vm_management'
        }
      ]
    };
  }

  // Generate troubleshooting response
  generateTroubleshootingResponse(message, context) {
    const solutions = [
      "Let me help you troubleshoot this issue. First, try restarting the affected app. If that doesn't work, check your network connection.",
      "Common issues can be resolved by clearing app cache or restarting your VM. Would you like me to walk you through these steps?",
      "I can run a quick diagnostic to identify the problem. This usually takes just a few seconds. Shall I proceed?"
    ];
    
    return {
      content: solutions[Math.floor(Math.random() * solutions.length)],
      intent: 'troubleshooting',
      confidence: 0.9,
      suggestions: [
        "Run system diagnostic",
        "Clear app cache",
        "Restart VM"
      ],
      actionItems: [
        {
          type: 'run_diagnostic',
          label: 'Run Diagnostic',
          action: 'start_system_diagnostic'
        }
      ]
    };
  }

  // Generate general response
  generateGeneralResponse(message, intent) {
    const responses = [
      "I understand you're asking about that. While I specialize in ShaydZ AVMo features, I'll do my best to help. Could you be more specific?",
      "That's an interesting question! For the best assistance, try asking about app recommendations, VM management, or troubleshooting.",
      "I'm here to help with your ShaydZ AVMo experience. Feel free to ask about apps, performance, or any technical issues you're facing."
    ];
    
    return {
      content: responses[Math.floor(Math.random() * responses.length)],
      intent: intent.type,
      confidence: intent.confidence,
      suggestions: [
        "Help me find apps",
        "Check my VM status",
        "What can you do?"
      ]
    };
  }

  // Store conversation in database
  async storeConversation(userId, userMessage, aiResponse) {
    try {
      if (this.db) {
        await this.db.collection('chat_conversations').insertOne({
          userId,
          userMessage,
          aiResponse,
          timestamp: new Date()
        });
      }
    } catch (error) {
      console.error('Error storing conversation:', error);
    }
  }

  // Get conversation history
  getConversationHistory(userId) {
    return this.conversationHistory.get(userId) || [];
  }
}

// POST /chat/message - Send message to AI assistant
router.post('/message', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const userId = req.user.id;
    const { message, context } = req.body;
    
    if (!message || message.trim().length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Message is required'
      });
    }
    
    const assistant = new AIAssistant(db);
    const response = await assistant.processMessage(userId, message.trim(), context);
    
    res.json({
      success: true,
      data: {
        response: response.content,
        intent: response.intent,
        confidence: response.confidence,
        suggestions: response.suggestions || [],
        actionItems: response.actionItems || [],
        timestamp: new Date()
      }
    });
  } catch (error) {
    console.error('Chat message error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to process message'
    });
  }
});

// GET /chat/history - Get conversation history
router.get('/history', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const userId = req.user.id;
    const limit = parseInt(req.query.limit) || 50;
    
    let history = [];
    if (db) {
      history = await db.collection('chat_conversations')
        .find({ userId })
        .sort({ timestamp: -1 })
        .limit(limit)
        .toArray();
    }
    
    res.json({
      success: true,
      data: {
        history: history.reverse(), // Show oldest first
        count: history.length
      }
    });
  } catch (error) {
    console.error('Chat history error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get chat history'
    });
  }
});

// DELETE /chat/history - Clear conversation history
router.delete('/history', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const userId = req.user.id;
    
    if (db) {
      await db.collection('chat_conversations').deleteMany({ userId });
    }
    
    // Clear in-memory history
    const assistant = new AIAssistant(db);
    assistant.conversationHistory.delete(userId);
    
    res.json({
      success: true,
      message: 'Chat history cleared successfully'
    });
  } catch (error) {
    console.error('Clear history error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to clear chat history'
    });
  }
});

module.exports = router;