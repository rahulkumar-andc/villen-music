"""
Rate Limiting Middleware
Simple IP-based rate limiting for API protection.
"""

import time
from collections import defaultdict
from django.http import JsonResponse


class RateLimitMiddleware:
    """
    Simple rate limiting middleware.
    Limits requests per IP address within a time window.
    """
    
    def __init__(self, get_response):
        self.get_response = get_response
        self.requests = defaultdict(list)  # {ip: [timestamp1, timestamp2, ...]}
        self.rate_limit = 120  # requests per window
        self.window = 60  # seconds
    
    def __call__(self, request):
        # Only rate limit API endpoints
        if not request.path.startswith('/api/'):
            return self.get_response(request)
        
        ip = self.get_client_ip(request)
        now = time.time()
        
        # Clean old requests
        self.requests[ip] = [
            ts for ts in self.requests[ip]
            if now - ts < self.window
        ]
        
        # Check rate limit
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
