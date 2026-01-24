# 🚀 VILLEN MUSIC - LOCAL TESTING & DEPLOYMENT GUIDE

## Quick Start (5 minutes)

### Prerequisites
```bash
# Check you have these installed
python3 --version        # Python 3.8+
node --version          # Node.js 14+
npm --version           # npm 6+
```

### Run All Tests Locally

```bash
# Make script executable
chmod +x run_all_tests.sh
chmod +x LOCAL_TEST_GUIDE.sh

# Run interactive guide (recommended for first time)
./LOCAL_TEST_GUIDE.sh

# Or run all tests automatically
./run_all_tests.sh
```

The script will:
- ✅ Check prerequisites
- ✅ Setup virtual environment
- ✅ Install dependencies
- ✅ Run backend tests
- ✅ Run frontend tests
- ✅ Run mobile tests (if Flutter installed)
- ✅ Generate coverage reports
- ✅ Verify all fixes are in place

---

## Step-by-Step Local Setup

### Step 1: Backend Testing

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cat > .env.local << 'EOF'
SECRET_KEY=dev-secret-key-12345678901234567890123456789012345
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=sqlite:///db.sqlite3
CORS_ALLOWED_ORIGINS=http://localhost:3000
EOF

# Run migrations
python manage.py migrate

# Run tests
python manage.py test music --verbosity=2

# Optional: Check coverage
pip install pytest pytest-django pytest-cov
pytest --cov=music --cov-report=html
# Open htmlcov/index.html in browser

# Optional: Run with Django test server
python manage.py runserver 8000
# Backend runs on http://localhost:8000
```

**Expected Output:**
```
✅ Running tests...
✅ test_auth.py - PASS
✅ test_search.py - PASS
✅ test_rate_limiting.py - PASS
✅ test_security.py - PASS
Ran 12 tests in 0.234s - OK
```

---

### Step 2: Frontend Testing

```bash
cd frontend

# Install dependencies
npm install --legacy-peer-deps

# Run linting
npm run lint

# Build check
npm run build

# Start dev server
npm start
# Frontend runs on http://localhost:3000

# In another terminal, run tests
npm test -- --passWithNoTests
```

**Expected Output:**
```
✅ Compiled successfully!
You can now view villen-music in the browser
Local: http://localhost:3000
```

---

### Step 3: Mobile Testing (Optional)

```bash
cd villen_music_flutter

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test

# Build APK
flutter build apk --release
# APK will be in: build/app/outputs/flutter-apk/app-release.apk
```

---

## Verification Checklist

After running tests, verify these fixes are in place:

### Backend ✅
```bash
cd backend

# FIX #1: SECRET_KEY from environment
grep "SECRET_KEY = os.getenv" core/settings.py && echo "✅ FIX #1"

# FIX #2: HttpOnly cookies
grep "httponly=True" core/settings.py && echo "✅ FIX #2"

# FIX #3: CSRF protection
grep "CsrfViewMiddleware" core/settings.py && echo "✅ FIX #3"

# FIX #5: Rate limiting
grep "AdminRateLimitMiddleware" core/middleware.py && echo "✅ FIX #5"

# FIX #12: Cache headers
grep "Cache-Control" music/views.py && echo "✅ FIX #12"

# FIX #13: Token refresh
grep "refresh" music/urls.py && echo "✅ FIX #13"

# FIX #20: Security headers
grep "HSTS\|CSP" core/settings.py && echo "✅ FIX #20"
```

### Frontend ✅
```bash
cd frontend

# FIX #13: Token refresh
grep "refreshAccessToken" app.js && echo "✅ FIX #13"

# FIX #14: apiFetch wrapper
grep "async function apiFetch" app.js && echo "✅ FIX #14"

# FIX #18: Smart caching
grep "getCachedData\|setCachedData" app.js && echo "✅ FIX #18"

# FIX #23: PWA manifest
[ -f "manifest.json" ] && echo "✅ FIX #23"

# FIX #24: Analytics
[ -f "analytics.js" ] && echo "✅ FIX #24"
```

### Mobile ✅
```bash
cd villen_music_flutter

# FIX #15: Download retry
grep "maxRetries" lib/services/download_service.dart && echo "✅ FIX #15"

# FIX #16: Disk space check
grep "_hasSufficientDiskSpace" lib/services/download_service.dart && echo "✅ FIX #16"

# FIX #17: Connection detection
grep "connectivity_plus" pubspec.yaml && echo "✅ FIX #17"

# FIX #9: Error boundary
grep "runZonedGuarded" lib/main.dart && echo "✅ FIX #9"
```

---

## Common Issues & Fixes

### Issue: Python venv not activating
**Solution:**
```bash
# Windows
venv\Scripts\activate.bat

# Mac/Linux with fish shell
source venv/bin/activate.fish

# Use python directly
./venv/bin/python manage.py test
```

### Issue: npm install fails
**Solution:**
```bash
# Clear npm cache
npm cache clean --force

# Install with legacy peer deps
npm install --legacy-peer-deps

# Or upgrade npm
npm install -g npm@latest
```

### Issue: Tests fail with database error
**Solution:**
```bash
# Remove old database
rm backend/db.sqlite3

# Create new one
cd backend
python manage.py migrate
python manage.py test
```

### Issue: Port 3000 or 8000 already in use
**Solution:**
```bash
# Kill process on port 8000
lsof -ti:8000 | xargs kill -9

# Kill process on port 3000
lsof -ti:3000 | xargs kill -9

# Or use different ports
python manage.py runserver 8001
npm start -- --port 3001
```

---

## Test Reports & Coverage

After running tests, check these reports:

### Backend Coverage
```bash
# Generate and open coverage report
cd backend
pytest --cov=music --cov-report=html
open htmlcov/index.html  # or use your browser
```

**Target:** > 80% coverage ✅

### Security Scan
```bash
cd backend
pip install bandit
bandit -r . -f csv -o bandit_report.csv
```

### Linting Report
```bash
cd backend
pip install flake8
flake8 . --max-line-length=100 --statistics
```

---

## Performance Testing (Local)

### Load Testing with Apache Bench
```bash
# Install ab (comes with Apache)
which ab  # or install Apache

# Test single endpoint
ab -n 1000 -c 10 http://localhost:8000/search/?q=test

# Analyze results
# Requests/sec should be > 50
# Mean time should be < 200ms
```

### API Response Time
```bash
# In backend terminal
python manage.py runserver

# In another terminal
curl -w "@curl-format.txt" -o /dev/null http://localhost:8000/trending/
```

---

## Environment Variables for Local Testing

Create `.env.local` in backend directory:

```bash
# Security
SECRET_KEY=dev-secret-key-change-this-in-production
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,127.0.0.1:3000

# Database (SQLite for local)
DATABASE_URL=sqlite:///db.sqlite3

# Frontend
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000

# Email (Console for local)
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend

# Logging
LOG_LEVEL=DEBUG

# Cache
CACHE_URL=locmem://
```

---

## Ready for Deployment? ✅

Before deploying, verify:

- [ ] All tests pass locally
- [ ] Coverage > 80%
- [ ] No security warnings
- [ ] No linting errors
- [ ] All 30 fixes verified
- [ ] Documentation reviewed
- [ ] Environment variables prepared
- [ ] Database backup planned

---

## Deployment to Staging

### 1. Create Production Environment File

```bash
# Generate secure SECRET_KEY
python3 << 'EOF'
import secrets
print(secrets.token_urlsafe(50))
EOF

# Create .env.staging
cat > backend/.env.staging << 'EOF'
SECRET_KEY=<generated-key-above>
DEBUG=False
ALLOWED_HOSTS=staging-api.yourdomain.com
DATABASE_URL=postgresql://user:pass@db-host/villen_staging
CORS_ALLOWED_ORIGINS=https://staging.yourdomain.com
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
EOF
```

### 2. Deploy to Staging Server

**Option A: Using Render.com (Recommended)**
```bash
# Push to GitHub
git add .
git commit -m "All 30 fixes implemented and tested locally"
git push origin main

# Render automatically deploys from GitHub
# Monitor deployment at: https://dashboard.render.com
```

**Option B: Using Docker**
```bash
# Build Docker image
docker build -t villen-music:staging ./backend

# Run container
docker run -e SECRET_KEY=$SECRET_KEY \
           -e DATABASE_URL=$DATABASE_URL \
           -p 8000:8000 \
           villen-music:staging

# Container runs on http://localhost:8000
```

### 3. Verify Staging Deployment

```bash
# Test API
curl https://staging-api.yourdomain.com/health/

# Check logs
docker logs <container-id>

# Monitor metrics
open https://your-monitoring-dashboard.com
```

### 4. Run Integration Tests Against Staging

```bash
# Update API_BASE in tests
export API_URL=https://staging-api.yourdomain.com

# Run tests
cd backend
python manage.py test music --settings=core.settings --keepdb
```

---

## Deployment to Production

**⚠️ IMPORTANT: Only after staging is verified for 24+ hours**

### 1. Final Checklist

```bash
# Review changes
git log --oneline -10

# Backup production database
pg_dump $PROD_DB_URL > backups/prod_$(date +%Y%m%d_%H%M%S).sql.gz

# Verify all environment variables
env | grep -E "SECRET_KEY|DEBUG|DATABASE"
```

### 2. Deploy Production

```bash
# Create production environment
cat > backend/.env.production << 'EOF'
SECRET_KEY=<production-secret-key>
DEBUG=False
ALLOWED_HOSTS=api.yourdomain.com
DATABASE_URL=postgresql://user:pass@prod-db/villen
CORS_ALLOWED_ORIGINS=https://yourdomain.com
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
EOF

# Deploy (same as staging)
git push origin main
# Or: docker build & deploy manually

# Verify
curl https://api.yourdomain.com/health/
```

### 3. Post-Deployment Monitoring

```bash
# Monitor metrics for 1 hour
tail -f logs/production.log

# Alert thresholds:
# - Error rate > 1%
# - Response time > 500ms
# - Database down
# - Disk space > 90%

# Quick health check
curl https://api.yourdomain.com/health/live
curl https://api.yourdomain.com/health/ready
```

---

## Rollback Procedure (If Needed)

```bash
# If deployment has critical issues:

# 1. Restore database
pg_restore -U postgres -d villen backups/prod_YYYYMMDD_HHMMSS.sql.gz

# 2. Redeploy previous version
git checkout <previous-commit>
git push origin main

# 3. Verify
curl https://api.yourdomain.com/health/
```

---

## Success Checklist ✅

- ✅ All local tests passing
- ✅ All 30 fixes verified
- ✅ Code coverage > 80%
- ✅ Security scan clean
- ✅ No linting errors
- ✅ Staging deployment verified
- ✅ Production ready

**Congratulations! You're ready to deploy!** 🚀

---

**Questions?** Check the documentation:
- [SECURITY_AUDIT.md](SECURITY_AUDIT.md) - All security details
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - API endpoints
- [MONITORING_SETUP.md](MONITORING_SETUP.md) - Monitoring
- [README.md](README.md) - Project overview
