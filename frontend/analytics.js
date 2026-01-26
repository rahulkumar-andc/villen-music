/**
 * FIX #24: Analytics Service
 * 
 * Tracks user engagement and application events for analytics.
 * Events are stored locally and can be sent to analytics backend.
 * 
 * Usage:
 *   Analytics.trackEvent('song_played', { songId: '123', duration: 240 });
 *   Analytics.trackPageView('home');
 *   Analytics.trackError('api_error', { statusCode: 500 });
 */

class Analytics {
  static VERSION = '1.0.0';
  static MAX_EVENTS = 100;  // Max events to store locally
  
  // Storage key for analytics
  static STORAGE_KEY = 'villen_analytics_events';
  
  /**
   * Track a custom event
   * @param {string} eventName - Name of the event (e.g., 'song_played')
   * @param {object} properties - Event properties/metadata
   */
  static trackEvent(eventName, properties = {}) {
    try {
      const event = {
        timestamp: new Date().toISOString(),
        event: eventName,
        userId: Analytics.getUserId(),
        sessionId: Analytics.getSessionId(),
        ...properties,
      };
      
      Analytics._storeEvent(event);
      console.log(`📊 Analytics: ${eventName}`, properties);
    } catch (err) {
      console.error('Analytics error:', err);
    }
  }
  
  /**
   * Track page view
   * @param {string} pageName - Name of the page (e.g., 'home', 'search', 'player')
   */
  static trackPageView(pageName) {
    Analytics.trackEvent('page_view', {
      page: pageName,
      title: document.title,
      url: window.location.href,
    });
  }
  
  /**
   * Track error event
   * @param {string} errorType - Type of error
   * @param {object} details - Error details
   */
  static trackError(errorType, details = {}) {
    Analytics.trackEvent('error', {
      type: errorType,
      ...details,
      userAgent: navigator.userAgent,
    });
  }
  
  /**
   * Track music playback
   * @param {string} songId - Song ID
   * @param {string} title - Song title
   * @param {number} duration - Song duration in seconds
   */
  static trackMusicPlay(songId, title, duration) {
    Analytics.trackEvent('music_play', {
      songId,
      title,
      duration,
      quality: localStorage.getItem('audioQuality') || 'unknown',
    });
  }
  
  /**
   * Track search query
   * @param {string} query - Search query
   * @param {number} resultCount - Number of results
   */
  static trackSearch(query, resultCount) {
    Analytics.trackEvent('search', {
      query: query.substring(0, 50),  // Truncate for privacy
      resultCount,
      timestamp: new Date().toISOString(),
    });
  }
  
  /**
   * Track user action (like, unlike, download, etc.)
   * @param {string} action - Action type (like, unlike, download, share)
   * @param {string} songId - Song ID
   */
  static trackUserAction(action, songId) {
    Analytics.trackEvent(`user_${action}`, {
      songId,
    });
  }
  
  /**
   * Get or create user ID (persisted in localStorage)
   * @returns {string} User ID (UUID-like)
   */
  static getUserId() {
    let userId = localStorage.getItem('villen_user_id');
    if (!userId) {
      userId = Analytics._generateUUID();
      localStorage.setItem('villen_user_id', userId);
    }
    return userId;
  }
  
  /**
   * Get or create session ID (for current session)
   * @returns {string} Session ID
   */
  static getSessionId() {
    if (!window._villenSessionId) {
      window._villenSessionId = Analytics._generateUUID();
      window._villenSessionStart = new Date();
    }
    return window._villenSessionId;
  }
  
  /**
   * Get session duration in seconds
   * @returns {number} Duration in seconds
   */
  static getSessionDuration() {
    if (!window._villenSessionStart) return 0;
    return Math.floor((new Date() - window._villenSessionStart) / 1000);
  }
  
  /**
   * Retrieve all stored events
   * @returns {Array} Array of events
   */
  static getEvents() {
    try {
      const stored = localStorage.getItem(Analytics.STORAGE_KEY);
      return stored ? JSON.parse(stored) : [];
    } catch (err) {
      console.error('Error retrieving events:', err);
      return [];
    }
  }
  
  /**
   * Clear all stored events
   */
  static clearEvents() {
    localStorage.removeItem(Analytics.STORAGE_KEY);
    console.log('📊 Analytics: Events cleared');
  }
  
  /**
   * Send events to backend (when online)
   * @param {string} endpoint - Backend endpoint to send events to
   */
  static async sendEvents(endpoint = '/api/analytics/events') {
    try {
      const events = Analytics.getEvents();
      if (events.length === 0) return;
      
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({
          events,
          sessionDuration: Analytics.getSessionDuration(),
          appVersion: Analytics.VERSION,
        }),
      });
      
      if (response.ok) {
        Analytics.clearEvents();
        console.log('📊 Analytics: Events sent successfully');
      }
    } catch (err) {
      console.error('Failed to send analytics:', err);
      // Events remain stored for retry
    }
  }
  
  /**
   * Store event in localStorage
   * @private
   */
  static _storeEvent(event) {
    try {
      const events = Analytics.getEvents();
      events.push(event);
      
      // Keep only recent events (FIFO)
      if (events.length > Analytics.MAX_EVENTS) {
        events.shift();
      }
      
      localStorage.setItem(Analytics.STORAGE_KEY, JSON.stringify(events));
    } catch (err) {
      console.error('Error storing event:', err);
    }
  }
  
  /**
   * Generate UUID-like string
   * @private
   */
  static _generateUUID() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }
  
  /**
   * Initialize analytics (setup event listeners)
   * Should be called on app startup
   */
  static init() {
    // Track page views when section changes
    window.addEventListener('villen_section_changed', (e) => {
      Analytics.trackPageView(e.detail.section);
    });
    
    // Track errors
    window.addEventListener('error', (e) => {
      Analytics.trackError('js_error', {
        message: e.message,
        filename: e.filename,
        lineno: e.lineno,
      });
    });
    
    // Periodically send events when online
    setInterval(() => {
      if (navigator.onLine) {
        Analytics.sendEvents();
      }
    }, 60000); // Send every minute if online
    
    console.log('📊 Analytics initialized');
  }
}

// Initialize on page load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => Analytics.init());
} else {
  Analytics.init();
}
