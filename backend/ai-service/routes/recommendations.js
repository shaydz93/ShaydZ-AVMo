const express = require('express');
const router = express.Router();

// Simple collaborative filtering algorithm for app recommendations
class RecommendationEngine {
  constructor(db) {
    this.db = db;
  }

  // Get personalized app recommendations
  async getPersonalizedRecommendations(userId, limit = 10) {
    try {
      // Get user's app usage and preferences
      const userApps = await this.db.collection('user_app_interactions').find({ userId }).toArray();
      const userCategories = this.extractPreferredCategories(userApps);
      
      // Get popular apps in preferred categories
      const recommendations = await this.db.collection('app_recommendations')
        .find({
          category: { $in: userCategories },
          userId: { $ne: userId } // Exclude user's own apps
        })
        .sort({ score: -1, popularity: -1 })
        .limit(limit)
        .toArray();

      return recommendations;
    } catch (error) {
      console.error('Error getting personalized recommendations:', error);
      return this.getFallbackRecommendations(limit);
    }
  }

  // Get popular apps (fallback)
  async getFallbackRecommendations(limit = 10) {
    const popularApps = [
      {
        id: 'app_1',
        name: 'Virtual Office Suite',
        category: 'Productivity',
        description: 'Complete office productivity suite for virtual environments',
        iconName: 'doc.text',
        version: '2.1.0',
        size: '45MB',
        score: 4.8,
        popularity: 95,
        aiRecommendationReason: 'Highly popular among productivity users'
      },
      {
        id: 'app_2', 
        name: 'Secure Browser',
        category: 'Internet',
        description: 'Privacy-focused web browser with advanced security features',
        iconName: 'safari',
        version: '1.5.0',
        size: '32MB',
        score: 4.6,
        popularity: 88,
        aiRecommendationReason: 'Perfect for secure browsing'
      },
      {
        id: 'app_3',
        name: 'Development IDE',
        category: 'Developer Tools',
        description: 'Full-featured integrated development environment',
        iconName: 'chevron.left.forwardslash.chevron.right',
        version: '3.0.1',
        size: '128MB',
        score: 4.9,
        popularity: 82,
        aiRecommendationReason: 'Essential for developers'
      },
      {
        id: 'app_4',
        name: 'Media Player Pro',
        category: 'Entertainment',
        description: 'Advanced media player supporting all formats',
        iconName: 'play.circle',
        version: '2.3.0',
        size: '28MB',
        score: 4.4,
        popularity: 76,
        aiRecommendationReason: 'Great for multimedia content'
      },
      {
        id: 'app_5',
        name: 'Team Collaboration',
        category: 'Communication',
        description: 'Real-time team communication and collaboration platform',
        iconName: 'person.2',
        version: '1.8.0',
        size: '41MB',
        score: 4.7,
        popularity: 84,
        aiRecommendationReason: 'Ideal for team productivity'
      }
    ];

    return popularApps.slice(0, limit);
  }

  // Extract user's preferred categories from interaction data
  extractPreferredCategories(userApps) {
    const categoryCount = {};
    userApps.forEach(app => {
      categoryCount[app.category] = (categoryCount[app.category] || 0) + app.usageTime;
    });

    return Object.keys(categoryCount)
      .sort((a, b) => categoryCount[b] - categoryCount[a])
      .slice(0, 3); // Top 3 categories
  }

  // Record user interaction for learning
  async recordInteraction(userId, appId, interactionType, metadata = {}) {
    try {
      await this.db.collection('user_app_interactions').insertOne({
        userId,
        appId,
        interactionType, // 'view', 'install', 'launch', 'uninstall'
        metadata,
        timestamp: new Date()
      });
    } catch (error) {
      console.error('Error recording interaction:', error);
    }
  }
}

// GET /recommendations - Get personalized app recommendations
router.get('/', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const userId = req.user?.id || 'anonymous';
    const limit = parseInt(req.query.limit) || 10;
    
    const engine = new RecommendationEngine(db);
    const recommendations = await engine.getPersonalizedRecommendations(userId, limit);
    
    res.json({
      success: true,
      data: {
        recommendations,
        userId,
        count: recommendations.length,
        algorithm: 'collaborative_filtering_v1'
      }
    });
  } catch (error) {
    console.error('Recommendations error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get recommendations'
    });
  }
});

// POST /recommendations/interaction - Record user interaction
router.post('/interaction', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const userId = req.user?.id || 'anonymous';
    const { appId, interactionType, metadata } = req.body;
    
    if (!appId || !interactionType) {
      return res.status(400).json({
        success: false,
        error: 'appId and interactionType are required'
      });
    }
    
    const engine = new RecommendationEngine(db);
    await engine.recordInteraction(userId, appId, interactionType, metadata);
    
    res.json({
      success: true,
      message: 'Interaction recorded successfully'
    });
  } catch (error) {
    console.error('Interaction recording error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to record interaction'
    });
  }
});

// GET /recommendations/categories - Get trending categories
router.get('/categories', async (req, res) => {
  try {
    const trendingCategories = [
      { name: 'Productivity', trend: 'up', score: 92 },
      { name: 'Developer Tools', trend: 'up', score: 88 },
      { name: 'Communication', trend: 'stable', score: 84 },
      { name: 'Internet', trend: 'up', score: 82 },
      { name: 'Entertainment', trend: 'down', score: 76 }
    ];
    
    res.json({
      success: true,
      data: {
        categories: trendingCategories,
        lastUpdated: new Date()
      }
    });
  } catch (error) {
    console.error('Categories error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get trending categories'
    });
  }
});

module.exports = router;