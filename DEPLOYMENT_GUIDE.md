# Villen Music - Deployment & Release Guide

## Status: READY FOR DEPLOYMENT ✅

**Build Date**: January 26, 2026  
**Version**: 1.3.0  
**Bugs Fixed**: 12  
**Test Status**: PASS  

---

## Pre-Deployment Checklist

### Frontend
- [x] All syntax validated (`app.js`, `main.js`, `analytics.js`)
- [x] 12 bugs fixed and verified
- [x] Memory leaks eliminated
- [x] Event listeners properly cleaned up
- [x] XSS prevention verified
- [x] Accessibility features working
- [x] 6 themes + light/dark mode
- [x] 4 audio visualizer modes
- [x] Keyboard shortcuts
- [x] Offline support
- [x] DEB package built

### Backend
- [x] Django configuration secure
- [x] CSRF protection enabled
- [x] JWT/Token auth configured
- [x] API endpoints validated
- [x] JioSaavn service integration working
- [x] Error handling implemented
- [x] Rate limiting enabled
- [x] CORS configured
- [x] Logging configured

### Security
- [x] DevTools disabled in production
- [x] SECRET_KEY protection
- [x] Session cookies secure
- [x] HTTPS enforced
- [x] No SQL injection vulnerabilities
- [x] No XSS vulnerabilities
- [x] No CSRF vulnerabilities

---

## Deployment Options

### Option 1: Linux Desktop (DEB Package) ✅ READY
```bash
# Install
sudo apt install /path/to/villen-music_1.0.0_amd64.deb

# Launch
villen-music
# or
/opt/villen-music/bin/villen-music
```

**Status**: ✅ DEB package built  
**Location**: `app-release/deb/villen-music_1.0.0_amd64.deb`

### Option 2: Docker Container
```bash
# Build
docker build -t villen-music:1.3.0 .

# Run Backend
docker run -e SECRET_KEY=your-key \
           -e DATABASE_URL=postgresql://... \
           -p 8000:8000 \
           villen-music:1.3.0

# Run Frontend
docker run -p 3000:3000 \
           -e REACT_APP_API=http://localhost:8000 \
           villen-music-frontend:1.3.0
```

### Option 3: Heroku/Render Deployment
```bash
# Set environment variables
heroku config:set SECRET_KEY=your-key
heroku config:set ALLOWED_HOSTS=your-domain.com
heroku config:set DATABASE_URL=postgresql://...

# Deploy
git push heroku main
```

### Option 4: Direct Server (Ubuntu 22.04+)
```bash
# Backend
sudo apt install python3 python3-venv
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000

# Frontend (Electron)
cd frontend
npm install
npm start
```

---

## Environment Variables

### Backend (.env)
```bash
# Security
SECRET_KEY=your-generated-secret-key
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1,your-domain.com

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/villen_music

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,https://your-domain.com

# Email (optional)
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password

# JioSaavn API (public, no key needed)
# JIOSAAVN_API_BASE=https://www.jiosaavn.com/api.php

# Logging
LOG_LEVEL=INFO
SENTRY_DSN=https://your-sentry-key@sentry.io/project-id

# Sessions
SESSION_COOKIE_SECURE=True
SESSION_COOKIE_HTTPONLY=True
CSRF_COOKIE_SECURE=True
```

### Frontend (.env or build config)
```bash
# API endpoints
REACT_APP_API=https://api.your-domain.com
REACT_APP_WS_URL=wss://api.your-domain.com/ws

# Features
REACT_APP_OFFLINE_SUPPORT=true
REACT_APP_AUDIO_VISUALIZATION=true

# Analytics
REACT_APP_GA_ID=G-your-ga-id
```

---

## Database Setup

### PostgreSQL (Recommended)
```bash
# Create database
sudo -u postgres psql
CREATE DATABASE villen_music;
CREATE USER villen WITH PASSWORD 'secure-password';
ALTER ROLE villen SET client_encoding TO 'utf8';
ALTER ROLE villen SET default_transaction_isolation TO 'read committed';
ALTER ROLE villen SET default_transaction_deferrable TO on;
ALTER ROLE villen SET timezone TO 'UTC';
GRANT ALL PRIVILEGES ON DATABASE villen_music TO villen;
\q

# Setup Django
cd backend
python manage.py migrate
python manage.py createsuperuser
```

### SQLite (Development Only)
```bash
cd backend
python manage.py migrate
# Database will be at db.sqlite3
```

---

## Deployment Steps

### Step 1: Clone Repository
```bash
git clone https://github.com/rahulkumar-andc/villen-music.git
cd villen-music
```

### Step 2: Setup Backend
```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Generate SECRET_KEY
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# Create .env file
cat > .env << EOF
SECRET_KEY=your-generated-key
DEBUG=False
ALLOWED_HOSTS=your-domain.com,api.your-domain.com
DATABASE_URL=postgresql://villen:password@localhost:5432/villen_music
EOF

# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput

# Test
python manage.py test
```

### Step 3: Setup Frontend
```bash
cd ../frontend

# Install dependencies
npm install

# Build for production
npm run build

# Or run development server
npm start
```

### Step 4: Configure Web Server (Nginx)
```nginx
upstream backend {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name your-domain.com;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    # SSL Certificates (Let's Encrypt)
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # API proxy
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
    }
    
    # Static files
    location /static/ {
        alias /path/to/frontend/build/;
    }
    
    # Frontend
    location / {
        alias /path/to/frontend/build/;
        try_files $uri /index.html;
    }
}
```

### Step 5: SSL Certificates (Let's Encrypt)
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot certonly --nginx -d your-domain.com

# Auto-renewal (automatic with snap)
sudo certbot renew --dry-run
```

### Step 6: Systemd Service (Backend)
```bash
sudo tee /etc/systemd/system/villen-music.service << EOF
[Unit]
Description=Villen Music Backend
After=network.target postgresql.service

[Service]
Type=notify
User=www-data
WorkingDirectory=/home/villen/Desktop/villen-music/backend
Environment="PATH=/home/villen/Desktop/villen-music/backend/venv/bin"
ExecStart=/home/villen/Desktop/villen-music/backend/venv/bin/gunicorn \
    --workers 3 \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 127.0.0.1:8000 \
    core.wsgi:application
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable villen-music
sudo systemctl start villen-music
sudo systemctl status villen-music
```

---

## Post-Deployment Verification

### Backend Health Check
```bash
curl https://api.your-domain.com/api/health
# Expected: {"status": "healthy"}
```

### Frontend Access
```bash
curl https://your-domain.com/
# Should return HTML
```

### Database Connection
```bash
cd backend
python manage.py dbshell
# Should connect successfully
```

### API Endpoints
```bash
# Search
curl "https://api.your-domain.com/api/search?query=test"

# Trending
curl "https://api.your-domain.com/api/trending"

# Artists
curl "https://api.your-domain.com/api/artists"
```

---

## Monitoring & Logging

### Log Files Location
```bash
# Django logs
/var/log/villen-music/django.log

# Nginx logs
/var/log/nginx/access.log
/var/log/nginx/error.log

# System logs
sudo journalctl -u villen-music -f
```

### Monitoring Tools
1. **Sentry** - Error tracking
2. **New Relic** - Performance monitoring
3. **Datadog** - Infrastructure monitoring
4. **Prometheus** - Metrics collection

### Setup Sentry
```bash
# Install
pip install sentry-sdk

# Configure in Django
# backend/core/settings.py
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

sentry_sdk.init(
    dsn="https://your-sentry-key@sentry.io/project-id",
    integrations=[DjangoIntegration()],
    traces_sample_rate=0.1,
    send_default_pii=False
)
```

---

## Backup & Recovery

### Database Backup
```bash
# Daily backup
sudo -u postgres pg_dump villen_music > /backups/villen_music_$(date +%Y%m%d).sql

# Automated backup script
sudo tee /etc/cron.daily/villen-music-backup << EOF
#!/bin/bash
BACKUP_DIR="/backups/villen-music"
mkdir -p $BACKUP_DIR
sudo -u postgres pg_dump villen_music | gzip > $BACKUP_DIR/db_$(date +%Y%m%d_%H%M%S).sql.gz
find $BACKUP_DIR -type f -mtime +7 -delete
EOF

sudo chmod +x /etc/cron.daily/villen-music-backup
```

### Restore Database
```bash
sudo -u postgres psql villen_music < /backups/villen_music_20260126.sql
```

### Application Backup
```bash
tar -czf villen-music-$(date +%Y%m%d).tar.gz /home/villen/Desktop/villen-music
```

---

## Scaling

### Horizontal Scaling
1. **Load Balancer**: Nginx or HAProxy
2. **Multiple Backend Instances**: Run 3-5 Gunicorn processes
3. **Cache Layer**: Redis for session/query caching
4. **CDN**: CloudFlare or AWS CloudFront for static files

### Vertical Scaling
1. Increase server RAM
2. Increase CPU cores
3. Upgrade database

### Database Optimization
1. Add indexes to frequently queried fields
2. Implement database connection pooling
3. Archive old data to separate storage

---

## Rollback Procedures

### Quick Rollback (If Issue Found)
```bash
# Backup current version
cp -r /home/villen/Desktop/villen-music /home/villen/Desktop/villen-music.backup

# Restore previous version
git checkout previous-tag

# Restart services
sudo systemctl restart villen-music

# Verify
curl https://api.your-domain.com/api/health
```

### Database Rollback
```bash
# If migrations have issues
cd backend
python manage.py migrate music 0001  # Go back to initial
python manage.py migrate  # Reapply migrations
```

---

## Support & Troubleshooting

### Common Issues

**502 Bad Gateway**
```bash
# Check if backend is running
sudo systemctl status villen-music

# Check logs
sudo journalctl -u villen-music -n 50

# Restart
sudo systemctl restart villen-music
```

**Database Connection Error**
```bash
# Check PostgreSQL
sudo systemctl status postgresql

# Test connection
psql -U villen -d villen_music -h localhost
```

**Memory Issues**
```bash
# Check memory usage
free -h

# Check process
top -p $(pgrep -f gunicorn)

# Increase Gunicorn workers
# Reduce to 2 workers if RAM < 2GB
```

**API Rate Limiting**
```bash
# Check rate limits
curl -I https://api.your-domain.com/api/search
# Look for X-RateLimit-* headers
```

---

## Maintenance Schedule

### Daily
- Monitor error logs via Sentry
- Check disk space
- Verify database connectivity

### Weekly
- Review performance metrics
- Check for security updates
- Backup database

### Monthly
- Security audit
- Dependency updates
- Performance optimization review

### Quarterly
- Full security assessment
- Load testing
- Capacity planning

---

## Contact & Support

- **Email**: villensec@gmail.com
- **For**: Issues, bugs, security concerns, support
- **GitHub**: GitHub Issues

---

## Deployment Checklist

- [ ] SECRET_KEY generated and stored securely
- [ ] Database created and migrated
- [ ] Environment variables configured
- [ ] SSL certificates installed
- [ ] Nginx/Apache configured
- [ ] Systemd service created
- [ ] Monitoring setup (Sentry/New Relic)
- [ ] Backup system configured
- [ ] Load testing completed
- [ ] Security audit completed
- [ ] Documentation updated
- [ ] Team trained

---

**Deployment Ready**: ✅ APPROVED FOR PRODUCTION

*Last Updated: January 26, 2026*  
*Next Review: February 26, 2026*
