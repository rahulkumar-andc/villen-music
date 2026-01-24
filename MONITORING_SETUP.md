# FIX #28: Monitoring Setup Configuration
#
# Comprehensive monitoring for VILLEN Music application
# Includes metrics, logging, alerting, and dashboards
#

# ==================== DATADOG CONFIGURATION ====================
# Deploy this configuration to set up Datadog monitoring

datadog:
  # API Configuration
  api_key: "${DATADOG_API_KEY}"
  app_key: "${DATADOG_APP_KEY}"
  site: "datadoghq.com"  # or datadoghq.eu for EU
  
  # Agent Configuration
  agent:
    log_level: "INFO"
    hostname: "villen-api-prod"
    tags:
      - "env:production"
      - "service:villen-music"
      - "version:1.0.0"
  
  # APM (Application Performance Monitoring)
  apm:
    enabled: true
    service_name: "villen-music"
    sample_rate: 0.1  # 10% of requests
    trace_sampling:
      - pattern: "^/health"
        sample_rate: 0.01
      - pattern: "^/stream"
        sample_rate: 0.05
      - default_sample_rate: 0.1
  
  # Logging
  logs:
    enabled: true
    service: "villen-music"
    source: "django"
    log_processing:
      - type: "attribute-remapper"
        sources: ["request_id"]
        target: "trace_id"

# ==================== PROMETHEUS CONFIGURATION ====================
# For self-hosted monitoring

prometheus:
  scrape_interval: 15s
  evaluation_interval: 15s
  
  scrape_configs:
    # Django application metrics
    - job_name: 'villen-api'
      static_configs:
        - targets: ['localhost:8000']
      metrics_path: '/metrics/'
      scrape_interval: 30s
    
    # PostgreSQL database metrics
    - job_name: 'postgres'
      static_configs:
        - targets: ['localhost:9187']
    
    # Redis cache metrics (if used)
    - job_name: 'redis'
      static_configs:
        - targets: ['localhost:6379']
    
    # Node exporter (system metrics)
    - job_name: 'node'
      static_configs:
        - targets: ['localhost:9100']

# ==================== ALERTING RULES ====================

alerting:
  alert_rules:
    
    # API Performance Alerts
    - name: "API High Response Time"
      description: "API response time exceeds 1 second"
      condition: "p95_response_time > 1000"  # milliseconds
      severity: "warning"
      threshold: 5  # minutes
      channels: ["#alerts", "on-call@villen"]
    
    - name: "API Error Rate High"
      description: "More than 1% of requests returning 5xx errors"
      condition: "error_rate > 0.01"
      severity: "critical"
      threshold: 2  # minutes
      channels: ["#alerts-critical", "on-call@villen", "pagerduty"]
    
    - name: "Service Down"
      description: "API service is not responding"
      condition: "up == 0"
      severity: "critical"
      threshold: 1  # minute
      channels: ["#alerts-critical", "pagerduty", "sms"]
    
    # Database Alerts
    - name: "Database Connection Pool Exhausted"
      description: "Database connections at > 90% capacity"
      condition: "db_connections / max_connections > 0.9"
      severity: "critical"
      threshold: 2  # minutes
      channels: ["#alerts-critical", "pagerduty"]
    
    - name: "Database Query Performance"
      description: "Slow queries detected (> 5 seconds)"
      condition: "slow_query_count > 10"
      severity: "warning"
      threshold: 5  # minutes
      channels: ["#alerts"]
    
    # Resource Alerts
    - name: "High CPU Usage"
      description: "CPU usage > 80%"
      condition: "cpu_usage > 0.8"
      severity: "warning"
      threshold: 10  # minutes
      channels: ["#alerts"]
    
    - name: "High Memory Usage"
      description: "Memory usage > 85%"
      condition: "memory_usage > 0.85"
      severity: "warning"
      threshold: 10  # minutes
      channels: ["#alerts"]
    
    - name: "Disk Space Low"
      description: "Disk usage > 90%"
      condition: "disk_usage > 0.9"
      severity: "critical"
      threshold: 15  # minutes
      channels: ["#alerts-critical"]
    
    # Business Logic Alerts
    - name: "Search Failed Requests High"
      description: "Search endpoint failure rate > 2%"
      condition: "search_error_rate > 0.02"
      severity: "warning"
      threshold: 5  # minutes
      channels: ["#alerts"]
    
    - name: "Stream Failures Detected"
      description: "Audio stream failures > 100 per minute"
      condition: "stream_failures_per_minute > 100"
      severity: "critical"
      threshold: 2  # minutes
      channels: ["#alerts-critical", "pagerduty"]

# ==================== DASHBOARDS ====================

grafana:
  dashboards:
    - name: "VILLEN Music - Overview"
      panels:
        - title: "Request Rate"
          metric: "rate(requests_total[5m])"
          type: "graph"
        - title: "Response Time P95"
          metric: "histogram_quantile(0.95, response_time_seconds)"
          type: "gauge"
        - title: "Error Rate"
          metric: "rate(errors_total[5m])"
          type: "graph"
        - title: "Active Users"
          metric: "active_sessions_count"
          type: "stat"
    
    - name: "VILLEN Music - Database"
      panels:
        - title: "Query Performance"
          metric: "database_query_duration_seconds"
          type: "heatmap"
        - title: "Connection Pool"
          metric: "database_connections"
          type: "gauge"
        - title: "Replication Lag"
          metric: "database_replication_lag_seconds"
          type: "graph"
    
    - name: "VILLEN Music - Infrastructure"
      panels:
        - title: "CPU Usage"
          metric: "node_cpu_seconds_total"
          type: "graph"
        - title: "Memory Usage"
          metric: "node_memory_MemAvailable_bytes"
          type: "gauge"
        - title: "Disk I/O"
          metric: "node_disk_io_time_seconds_total"
          type: "graph"

# ==================== LOGGING CONFIGURATION ====================

logging:
  # ELK Stack (Elasticsearch, Logstash, Kibana)
  elasticsearch:
    host: "elasticsearch.villen-prod"
    port: 9200
    index_pattern: "villen-logs-%{+YYYY.MM.dd}"
    
  logstash:
    filter_rules:
      - type: "request"
        pattern: "^HTTP \d+ \d+ ms$"
        fields:
          - method
          - status_code
          - duration_ms
      - type: "error"
        pattern: "ERROR"
        severity: "high"
      - type: "debug"
        pattern: "DEBUG"
        severity: "low"
  
  kibana:
    dashboards:
      - "API Request Timeline"
      - "Error Rate Distribution"
      - "Response Time Percentiles"

# ==================== HEALTH CHECK CONFIGURATION ====================

health_checks:
  # Liveness probe: is the service running?
  liveness:
    endpoint: "/health/live"
    interval: 10  # seconds
    timeout: 5    # seconds
    threshold: 3  # failures before restart
  
  # Readiness probe: is the service ready for traffic?
  readiness:
    endpoint: "/health/ready"
    interval: 5   # seconds
    timeout: 3    # seconds
    threshold: 1  # failures before removing from LB
  
  # Startup probe: has the service started?
  startup:
    endpoint: "/health/startup"
    interval: 5   # seconds
    timeout: 3    # seconds
    threshold: 5  # failures before restart
    initial_delay: 10  # seconds

# ==================== SYNTHETIC MONITORING ====================

synthetic_tests:
  # Monitor critical user journeys
  - name: "User Login Flow"
    endpoint: "https://api.villen-music.com"
    steps:
      - POST /auth/login/ with valid credentials
      - GET /user/profile/ with auth token
      - GET /trending/ with cache validation
    frequency: "5m"
    timeout: "30s"
    alert_on_failure: true
  
  - name: "Music Search"
    endpoint: "https://api.villen-music.com"
    steps:
      - GET /search/?q=song
      - Verify response time < 500ms
      - Verify results count > 0
    frequency: "10m"
    timeout: "10s"
    alert_on_failure: true
  
  - name: "Audio Stream"
    endpoint: "https://api.villen-music.com"
    steps:
      - GET /stream/<song_id>
      - Verify response headers contain Content-Type: audio
      - Verify stream is > 1MB
    frequency: "15m"
    timeout: "60s"
    alert_on_failure: true

# ==================== METRICS COLLECTION ====================

metrics:
  # Application metrics
  api:
    - requests_total
    - requests_duration_seconds
    - errors_total
    - cache_hits
    - cache_misses
    - db_queries
    - db_query_duration_seconds
  
  # Business metrics
  business:
    - songs_played_total
    - users_active_now
    - searches_performed_total
    - downloads_total
    - likes_total
  
  # Infrastructure metrics
  infrastructure:
    - cpu_usage_percent
    - memory_usage_bytes
    - disk_usage_percent
    - network_in_bytes
    - network_out_bytes

# ==================== RUNBOOKS ====================

runbooks:
  high_error_rate:
    description: "Handle situation when error rate exceeds threshold"
    steps:
      1. "Check Datadog dashboard for error patterns"
      2. "Review application logs for specific errors"
      3. "Check database health and query performance"
      4. "If database issue: check slow query log"
      5. "If application issue: check recent deployments"
      6. "If deployment caused: consider rollback"
      7. "Escalate to on-call engineer if unsure"
  
  database_performance:
    description: "Handle slow database queries"
    steps:
      1. "Check slow query log: SELECT * FROM pg_stat_statements"
      2. "Identify top slow queries"
      3. "Analyze query plan with EXPLAIN ANALYZE"
      4. "Check for missing indexes"
      5. "Check for full table scans"
      6. "Consider query optimization or index creation"
      7. "Monitor after changes"
  
  service_down:
    description: "Handle service downtime incident"
    steps:
      1. "Confirm service is down with health checks"
      2. "Check application logs for crashes"
      3. "Check infrastructure (CPU, memory, disk)"
      4. "Restart service if resource-constrained"
      5. "Check database connectivity"
      6. "Review recent deployments"
      7. "Initiate incident response protocol"

# ==================== DEPLOYMENT ====================

deployment:
  # Docker compose for local monitoring stack
  docker_compose: |
    version: '3.8'
    services:
      prometheus:
        image: prom/prometheus:latest
        ports:
          - "9090:9090"
        volumes:
          - ./prometheus.yml:/etc/prometheus/prometheus.yml
      
      grafana:
        image: grafana/grafana:latest
        ports:
          - "3000:3000"
        environment:
          - GF_SECURITY_ADMIN_PASSWORD=admin
      
      elasticsearch:
        image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
        environment:
          - discovery.type=single-node
        ports:
          - "9200:9200"
      
      kibana:
        image: docker.elastic.co/kibana/kibana:8.0.0
        ports:
          - "5601:5601"
        depends_on:
          - elasticsearch

# ==================== DOCUMENTATION ====================

documentation:
  links:
    - name: "Datadog Documentation"
      url: "https://docs.datadoghq.com"
    - name: "Prometheus Documentation"
      url: "https://prometheus.io/docs"
    - name: "Grafana Documentation"
      url: "https://grafana.com/docs"
    - name: "Elastic Stack Documentation"
      url: "https://www.elastic.co/guide"

# Last Updated: 2024-01-15
# Version: 1.0.0
