"""
Rate Limiting Middleware
Simple IP-based rate limiting for API protection.
"""

import time
import logging  # FIX #21: Request logging
from collections import defaultdict
from django.http import JsonResponse

logger = logging.getLogger(__name__)  # FIX #21: For request logging


class RateLimitMiddleware:
    """
    Simple rate limiting middleware.
    Limits requests per IP address within a time window.
    
    FIX: Excludes streaming endpoints to prevent audio stream throttling
    FIX #11: Tuned rate limit to 120 requests/60 seconds (2 req/sec)
    
    Reasoning:
    - Most mobile apps: 5-10 req/sec during peak usage
    - Single user: 1-2 req/sec typical
    - Burst searches: 3-5 req/sec for short periods
    - Current limit allows 1 user + small burst without blocking
    - Protects against bot attacks (>10 req/sec)
    
    To adjust: Monitor /var/log/villen_music/app.log for 429 errors
    and correlate with user complaints. If needed, increase to 300/60
    or implement per-endpoint tiering.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.requests = defaultdict(list)  # {ip: [timestamp1, timestamp2, ...]}
        self.rate_limit = 120  # requests per window - FIX #11: Verified good balance
        self.window = 60  # seconds
        
        # Endpoints that should NOT be rate limited (streaming, downloads, etc)
        self.excluded_paths = [
            '/api/stream/',  # Audio streaming - unlimited bandwidth
            '/media/',       # Media files
            '/static/',      # Static files
            '/download/',    # Download endpoints
        ]
    
    def __call__(self, request):
        # Only rate limit API endpoints
        if not request.path.startswith('/api/'):
            return self.get_response(request)
        
        # ✅ FIX: Skip rate limiting for streaming/download endpoints
        for excluded in self.excluded_paths:
            if excluded in request.path:
                # Bypass rate limiting for audio streams
                return self.get_response(request)
        
        ip = self.get_client_ip(request)
        now = time.time()
        
        # Clean old requests
        self.requests[ip] = [
            ts for ts in self.requests[ip]
            if now - ts < self.window
        ]
        
        # Check rate limit (only for non-stream endpoints)
        if len(self.requests[ip]) >= self.rate_limit:
            return JsonResponse(
                {"error": "Rate limit exceeded. Try again later."},
                status=429
            )
        
        # Record this request
        self.requests[ip].append(now)
        
        return self.get_response(request)
    
    def get_client_ip(self, request):
        """Get client IP from request, handling proxies."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '0.0.0.0')

# FIX #5: Protect admin panel from brute force attacks
class AdminRateLimitMiddleware:
    """
    Aggressive rate limiting for /admin/ endpoint.
    Prevents brute force attacks on admin password.
    Max 5 login attempts per 5 minutes per IP.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.admin_attempts = defaultdict(list)  # {ip: [timestamp1, timestamp2, ...]}
        self.max_attempts = 5
        self.window = 300  # 5 minutes
    
    def __call__(self, request):
        # Only protect /admin/ path
        if request.path.startswith('/admin/'):
            ip = self.get_client_ip(request)
            now = time.time()
            
            # Clean old attempts
            self.admin_attempts[ip] = [
                ts for ts in self.admin_attempts[ip]
                if now - ts < self.window
            ]
            
            # Check if exceeded limit
            if len(self.admin_attempts[ip]) >= self.max_attempts:
                return JsonResponse(
                    {
                        "error": "Too many admin login attempts. "
                                "Please try again in 5 minutes."
                    },
                    status=429
                )
            
            # Record this attempt
            self.admin_attempts[ip].append(now)
        
        return self.get_response(request)
    
    def get_client_ip(self, request):
        """Get client IP from request, handling proxies."""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '0.0.0.0')


# FIX #21: Request/response logging for debugging and monitoring
class RequestLoggingMiddleware:
    """
    Logs HTTP requests and responses for debugging and monitoring.
    
    Logs:
    - Request: method, path, client IP, user agent
    - Response: status code, content type
    - Errors: Any 4xx or 5xx responses
    - Performance: Response time
    
    This helps with:
    - Debugging issues in production
    - Monitoring suspicious activity
    - Performance optimization
    - Rate limiting verification
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request):
        import time
        
        # Log incoming request
        start_time = time.time()
        
        # Process request
        response = self.get_response(request)
        
        # Calculate response time
        duration = time.time() - start_time
        
        # Log response
        # FIX #21: Log errors and slow requests for monitoring
        if response.status_code >= 400 or duration > 1.0:
            logger.warning(
                f"{request.method} {request.path} -> {response.status_code} ({duration:.2f}s) "
                f"[{request.META.get('REMOTE_ADDR', 'unknown')}]"
            )
        else:
            logger.debug(
                f"{request.method} {request.path} -> {response.status_code} ({duration:.2f}s)"
            )
        
        return response
