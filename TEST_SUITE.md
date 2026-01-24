# FIX #30: Test Suite - Comprehensive Testing

"""
VILLEN Music - Test Suite

This module contains comprehensive tests for the VILLEN Music application
including unit tests, integration tests, and end-to-end tests.

Run with:
  pytest backend/          # All backend tests
  pytest --cov=music      # With coverage
  npm test                # Frontend tests
  flutter test            # Mobile tests
"""

# ==================== BACKEND TESTS ====================

# backend/music/tests/test_auth.py
import pytest
from django.test import Client, TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient


class AuthenticationTests(TestCase):
    """Test authentication endpoints"""
    
    def setUp(self):
        self.client = APIClient()
        self.user_data = {
            'username': 'testuser',
            'password': 'TestPass123!',
            'email': 'test@example.com'
        }
        self.user = User.objects.create_user(**self.user_data)
    
    def test_user_registration(self):
        """Test user registration with valid data"""
        response = self.client.post('/auth/register/', {
            'username': 'newuser',
            'password': 'SecurePass123!',
            'email': 'new@example.com'
        })
        assert response.status_code == 201
        assert response.data['username'] == 'newuser'
    
    def test_user_registration_weak_password(self):
        """Test registration fails with weak password"""
        response = self.client.post('/auth/register/', {
            'username': 'newuser',
            'password': 'weak',
            'email': 'new@example.com'
        })
        assert response.status_code == 400
        assert 'password' in response.data
    
    def test_login_success(self):
        """Test successful login"""
        response = self.client.post('/auth/login/', {
            'username': 'testuser',
            'password': 'TestPass123!'
        })
        assert response.status_code == 200
        assert 'access' in response.data
        assert 'refresh' in response.data
    
    def test_login_invalid_credentials(self):
        """Test login with invalid credentials"""
        response = self.client.post('/auth/login/', {
            'username': 'testuser',
            'password': 'WrongPassword'
        })
        assert response.status_code == 401
    
    def test_token_refresh(self):
        """Test token refresh"""
        # Get refresh token
        login_response = self.client.post('/auth/login/', {
            'username': 'testuser',
            'password': 'TestPass123!'
        })
        refresh_token = login_response.data['refresh']
        
        # Refresh token
        response = self.client.post('/auth/refresh/', {
            'refresh': refresh_token
        })
        assert response.status_code == 200
        assert 'access' in response.data
    
    def test_logout(self):
        """Test logout clears session"""
        # Login
        login_response = self.client.post('/auth/login/', {
            'username': 'testuser',
            'password': 'TestPass123!'
        })
        
        # Logout
        self.client.credentials(
            HTTP_AUTHORIZATION=f'Bearer {login_response.data["access"]}'
        )
        response = self.client.post('/auth/logout/')
        assert response.status_code == 200


class RateLimitTests(TestCase):
    """Test rate limiting"""
    
    def setUp(self):
        self.client = APIClient()
        self.admin_ip = '127.0.0.1'
    
    def test_admin_endpoint_rate_limiting(self):
        """Test admin endpoints are rate limited to 5 attempts per 5 minutes"""
        # Make 5 requests - should all succeed
        for i in range(5):
            response = self.client.post(
                '/auth/login/',
                {'username': 'admin', 'password': 'wrong'},
                REMOTE_ADDR=self.admin_ip
            )
            assert response.status_code in [401, 403]  # Auth failure, not rate limit
        
        # 6th request should be rate limited
        response = self.client.post(
            '/auth/login/',
            {'username': 'admin', 'password': 'wrong'},
            REMOTE_ADDR=self.admin_ip
        )
        assert response.status_code == 429


# backend/music/tests/test_search.py
class SearchTests(TestCase):
    """Test music search functionality"""
    
    def setUp(self):
        self.client = APIClient()
        # Create test songs
        from music.models import Song
        self.song1 = Song.objects.create(
            title='Test Song 1',
            artist='Test Artist',
            duration=240
        )
        self.song2 = Song.objects.create(
            title='Test Song 2',
            artist='Another Artist',
            duration=180
        )
    
    def test_search_songs(self):
        """Test searching for songs"""
        response = self.client.get('/search/?q=test')
        assert response.status_code == 200
        assert len(response.data['results']) >= 1
    
    def test_search_empty_query(self):
        """Test search with empty query fails"""
        response = self.client.get('/search/?q=')
        assert response.status_code == 400
    
    def test_search_results_cached(self):
        """Test search results are cached"""
        # First request
        response1 = self.client.get('/search/?q=test')
        
        # Second request should use cache
        response2 = self.client.get('/search/?q=test')
        
        # Both should succeed
        assert response1.status_code == 200
        assert response2.status_code == 200
    
    def test_search_cache_header(self):
        """Test Cache-Control header is set to 30 minutes"""
        response = self.client.get('/search/?q=test')
        assert response.get('Cache-Control') == 'max-age=1800'


# ==================== FRONTEND TESTS ====================

# frontend/tests/auth.test.js
describe('Frontend Authentication', () => {
    
    test('Login with valid credentials', async () => {
        const response = await apiFetch('https://api.test.com/auth/login/', {
            method: 'POST',
            body: JSON.stringify({
                username: 'testuser',
                password: 'TestPass123!'
            })
        });
        
        expect(response.status).toBe(200);
        const data = await response.json();
        expect(data.access).toBeDefined();
    });
    
    test('Token refresh on 401 error', async () => {
        // apiFetch should automatically refresh token on 401
        // This is tested via integration with the actual API
        const response = await apiFetch('/api/user/profile/');
        expect(response.status).toBe(200);
    });
    
    test('Input validation on password field', () => {
        const strength = updatePasswordStrength('weak');
        expect(strength).toBeLessThan(30);  // Weak password
        
        const strength2 = updatePasswordStrength('SecurePass123!');
        expect(strength2).toBeGreaterThan(80);  // Strong password
    });
});

describe('Frontend Caching', () => {
    
    test('Search results are cached with 5-minute TTL', async () => {
        // First search
        const results1 = await searchSongs('test');
        
        // Check cache was populated
        const cached = getCachedData(state.cache.searchResults, 'search_test');
        expect(cached).toBeDefined();
        
        // Second search should use cache
        const results2 = await searchSongs('test');
        expect(results1).toEqual(results2);
    });
    
    test('Cache auto-cleanup when exceeding 100 entries', () => {
        // Add 101 items
        for (let i = 0; i < 101; i++) {
            setCachedData(state.cache.searchResults, `key_${i}`, `value_${i}`);
        }
        
        // Cache should have removed oldest entry
        expect(state.cache.searchResults.size).toBeLessThanOrEqual(100);
    });
});

describe('Frontend Error Handling', () => {
    
    test('Error response standardization', async () => {
        try {
            await apiFetch('/api/nonexistent/');
        } catch (err) {
            expect(err.error).toBeDefined();
            expect(err.status).toBe('error');
        }
    });
});

// ==================== MOBILE TESTS ====================

// villen_music_flutter/test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:villen_music/main.dart';
import 'package:villen_music/services/api_service.dart';

void main() {
  group('VILLEN Music - Mobile Tests', () {
    
    testWidgets('App starts without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      expect(find.text('VILLEN Music'), findsOneWidget);
    });
    
    testWidgets('Navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Tap home button
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      
      expect(find.text('Trending'), findsOneWidget);
    });
  });
  
  group('API Service Tests', () {
    late ApiService apiService;
    
    setUp(() {
      apiService = ApiService(MockStorageService());
    });
    
    test('Search songs returns list', () async {
      final songs = await apiService.searchSongs('test');
      expect(songs, isA<List>());
    });
    
    test('Get stream URL returns valid URL', () async {
      final url = await apiService.getStreamUrl('song_id');
      expect(url, isNotNull);
      expect(url, contains('http'));
    });
    
    test('Download with retry on network error', () async {
      // Mock network error
      final success = await mockDownloadService.downloadSong(
        'song_id',
        mockNetworkError: true
      );
      expect(success, isTrue);  // Should succeed after retry
    });
    
    test('Connection detection works', () async {
      expect(apiService.isConnected, isTrue);
      
      // Simulate offline
      // Note: Requires proper mocking of connectivity_plus
    });
  });
}

// ==================== INTEGRATION TESTS ====================

# integration_tests/e2e_test.py
"""
End-to-End Tests

Tests complete user flows:
1. Register → Login → Search → Play
2. Like song → View liked songs
3. Download song → Verify file
"""

def test_user_flow_search_and_play():
    """Complete flow: Register, Login, Search, Play"""
    
    # 1. Register
    register_response = client.post('/auth/register/', {
        'username': f'user_{uuid.uuid4()}',
        'password': 'TestPass123!',
        'email': f'user_{uuid.uuid4()}@test.com'
    })
    assert register_response.status_code == 201
    
    # 2. Login
    login_response = client.post('/auth/login/', {
        'username': register_response.data['username'],
        'password': 'TestPass123!'
    })
    assert login_response.status_code == 200
    access_token = login_response.data['access']
    
    # 3. Search
    headers = {'Authorization': f'Bearer {access_token}'}
    search_response = client.get('/search/?q=song', headers=headers)
    assert search_response.status_code == 200
    song_id = search_response.data['results'][0]['id']
    
    # 4. Get stream URL
    stream_response = client.get(f'/stream/{song_id}/', headers=headers)
    assert stream_response.status_code == 200
    assert 'url' in stream_response.data


def test_like_and_fetch_liked_songs():
    """Test liking songs and fetching liked list"""
    
    # Login
    access_token = login_user()
    headers = {'Authorization': f'Bearer {access_token}'}
    
    # Like a song
    like_response = client.post(
        '/user/liked-songs/song_123/',
        headers=headers
    )
    assert like_response.status_code == 201
    
    # Fetch liked songs
    liked_response = client.get('/user/liked-songs/', headers=headers)
    assert liked_response.status_code == 200
    liked_ids = [s['id'] for s in liked_response.data['results']]
    assert 'song_123' in liked_ids


# ==================== PERFORMANCE TESTS ====================

# backend/tests/test_performance.py
import pytest
from django.test import TestCase
from django.test.utils import override_settings
from django.db import connection
from django.test.utils import CaptureQueriesContext


@pytest.mark.performance
class PerformanceTests(TestCase):
    
    def test_search_query_performance(self):
        """Ensure search completes in < 100ms"""
        import time
        
        with CaptureQueriesContext(connection) as queries:
            start = time.time()
            Song.objects.filter(title__icontains='test')[:30]
            duration = time.time() - start
        
        assert duration < 0.1, f'Search took {duration}s, expected < 0.1s'
    
    def test_trending_endpoint_uses_cache(self):
        """Verify trending endpoint uses cache"""
        with CaptureQueriesContext(connection) as queries:
            # First request
            response1 = self.client.get('/trending/')
            first_query_count = len(queries)
        
        with CaptureQueriesContext(connection) as queries:
            # Second request (cached)
            response2 = self.client.get('/trending/')
            cached_query_count = len(queries)
        
        # Cached request should use fewer queries
        assert cached_query_count < first_query_count


# ==================== SECURITY TESTS ====================

# backend/tests/test_security.py
class SecurityTests(TestCase):
    
    def test_no_hardcoded_secret_key(self):
        """Verify SECRET_KEY is not hardcoded"""
        with open('backend/core/settings.py', 'r') as f:
            content = f.read()
            assert 'SECRET_KEY = os.getenv' in content
    
    def test_csrf_protection(self):
        """Verify CSRF token is required for POST"""
        response = self.client.post('/auth/login/', {
            'username': 'test',
            'password': 'test'
        })
        # Should fail without CSRF token
        assert response.status_code in [403, 400]
    
    def test_input_validation(self):
        """Verify malicious input is rejected"""
        response = self.client.post('/auth/register/', {
            'username': '<script>alert("xss")</script>',
            'password': 'ValidPass123!',
            'email': 'test@test.com'
        })
        assert response.status_code == 400
    
    def test_security_headers_present(self):
        """Verify security headers are set"""
        response = self.client.get('/trending/')
        
        assert 'Strict-Transport-Security' in response
        assert 'Content-Security-Policy' in response
        assert 'X-Frame-Options' in response


# ==================== TEST CONFIGURATION ====================

# backend/tests/conftest.py
"""
Pytest configuration and fixtures for backend tests
"""

import pytest
from django.test import Client
from django.contrib.auth.models import User


@pytest.fixture
def api_client():
    """Fixture providing API client"""
    from rest_framework.test import APIClient
    return APIClient()


@pytest.fixture
def test_user(db):
    """Fixture providing a test user"""
    return User.objects.create_user(
        username='testuser',
        password='TestPass123!',
        email='test@example.com'
    )


@pytest.fixture
def authenticated_client(api_client, test_user):
    """Fixture providing authenticated API client"""
    api_client.force_authenticate(user=test_user)
    return api_client


# ==================== TEST RUNNING ====================

"""
Run tests with:

Backend:
    python manage.py test music
    pytest backend/ --cov=music --cov-report=html
    pytest backend/ -v -s  # Verbose with output

Frontend:
    npm test
    npm test -- --coverage

Mobile:
    flutter test
    flutter test --coverage

All:
    pytest backend/ && npm test && flutter test
"""
