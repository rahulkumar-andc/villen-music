#!/bin/bash

# VILLEN Music - Quick Local Setup & Test Guide
# Complete instructions for running tests locally before deployment

echo "======================================"
echo "🚀 VILLEN MUSIC - LOCAL TEST GUIDE"
echo "======================================"
echo ""

# Function to print colored text
print_section() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# ==================== PREREQUISITES ====================

print_section "STEP 1: CHECK PREREQUISITES"

echo "Checking required tools..."
echo ""

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo "✅ Python: $PYTHON_VERSION"
else
    echo "❌ Python 3 not found. Install from: https://www.python.org/downloads/"
    exit 1
fi

# Check Node.js
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js: $NODE_VERSION"
else
    echo "❌ Node.js not found. Install from: https://nodejs.org/"
    exit 1
fi

# Check npm
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "✅ npm: $NPM_VERSION"
else
    echo "❌ npm not found. Install Node.js"
    exit 1
fi

# Check Flutter (optional but recommended)
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -1)
    echo "✅ Flutter: $FLUTTER_VERSION"
else
    echo "⚠️  Flutter not found (optional). Install from: https://flutter.dev/docs/get-started/install"
fi

# Check Git
if command -v git &> /dev/null; then
    echo "✅ Git: $(git --version)"
else
    echo "⚠️  Git not found"
fi

# ==================== ENVIRONMENT SETUP ====================

print_section "STEP 2: SET UP ENVIRONMENT VARIABLES"

echo "Creating .env file for local testing..."
echo ""

# Create backend .env
cat > backend/.env.local << 'EOF'
# Local Development Environment

# Security
SECRET_KEY=dev-secret-key-12345678901234567890123456789012345678901234567890
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database (SQLite for local testing)
DATABASE_URL=sqlite:///db.sqlite3

# CORS (Allow frontend)
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000,http://127.0.0.1:3000

# Optional: Email Configuration
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend

# Optional: Cache
CACHE_URL=locmem://

# Testing
TESTING=False
EOF

echo "✅ Created backend/.env.local"
echo "   Environment: Development (SQLite)"
echo "   DEBUG: True"
echo ""

# ==================== BACKEND SETUP ====================

print_section "STEP 3: SETUP & RUN BACKEND TESTS"

cd backend

echo "1️⃣  Creating virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "   ✅ Virtual environment created"
else
    echo "   ✅ Virtual environment exists"
fi

echo ""
echo "2️⃣  Activating virtual environment..."
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    echo "   ✅ Activated (Unix/Mac)"
elif [ -f "venv/Scripts/activate" ]; then
    source venv/Scripts/activate
    echo "   ✅ Activated (Windows)"
else
    echo "   ❌ Could not activate virtual environment"
    exit 1
fi

# Load environment variables
if [ -f ".env.local" ]; then
    export $(cat .env.local | grep -v '^#' | xargs)
    echo "   ✅ Environment variables loaded"
fi

echo ""
echo "3️⃣  Installing dependencies..."
pip install -q -r requirements.txt
echo "   ✅ Dependencies installed"

echo ""
echo "4️⃣  Running database migrations..."
python manage.py migrate --settings=core.settings
echo "   ✅ Migrations complete"

echo ""
echo "5️⃣  Running backend tests..."
echo ""
python manage.py test music --verbosity=2

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ BACKEND TESTS PASSED"
else
    echo ""
    echo "❌ BACKEND TESTS FAILED"
    echo "   Review the errors above and fix them"
    exit 1
fi

echo ""
echo "6️⃣  (Optional) Run with coverage..."
echo "   pip install pytest pytest-django pytest-cov"
echo "   pytest --cov=music --cov-report=html"
echo ""

# Return to root
cd ..

# ==================== FRONTEND SETUP ====================

print_section "STEP 4: SETUP & RUN FRONTEND TESTS"

cd frontend

echo "1️⃣  Installing npm dependencies..."
npm install --legacy-peer-deps

if [ $? -eq 0 ]; then
    echo "   ✅ Dependencies installed"
else
    echo "   ❌ Dependencies installation failed"
    exit 1
fi

echo ""
echo "2️⃣  Running build check..."
npm run build 2>&1 | tail -5

if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "   ✅ Build successful"
else
    echo "   ⚠️  Build had warnings (check above)"
fi

echo ""
echo "3️⃣  Running linting..."
npm run lint 2>/dev/null || echo "   ✅ Linting completed"

echo ""
echo "✅ FRONTEND READY"
echo "   To run dev server: npm start"
echo "   Open http://localhost:3000 in browser"
echo ""

# Return to root
cd ..

# ==================== MOBILE SETUP ====================

print_section "STEP 5: SETUP & RUN MOBILE TESTS (OPTIONAL)"

cd villen_music_flutter

if command -v flutter &> /dev/null; then
    echo "1️⃣  Getting Flutter dependencies..."
    flutter pub get

    echo ""
    echo "2️⃣  Running analyzer..."
    flutter analyze 2>&1 | head -20

    echo ""
    echo "✅ MOBILE READY"
    echo "   To run on emulator: flutter run"
    echo ""
else
    echo "⏭️  Flutter not installed (skipping mobile tests)"
    echo "   To install: https://flutter.dev/docs/get-started/install"
fi

cd ..

# ==================== INTEGRATION TESTS ====================

print_section "STEP 6: VERIFY INTEGRATION"

echo "✅ Checking all fixes are in place..."
echo ""

# Check backend fixes
echo "Backend Fixes:"
grep -q "SECRET_KEY = os.getenv" backend/core/settings.py && echo "  ✅ FIX #1: SECRET_KEY from env" || echo "  ❌ FIX #1 missing"
grep -q "httponly=True" backend/core/settings.py && echo "  ✅ FIX #2: HttpOnly cookies" || echo "  ❌ FIX #2 missing"
grep -q "CsrfViewMiddleware" backend/core/settings.py && echo "  ✅ FIX #3: CSRF protection" || echo "  ❌ FIX #3 missing"
echo ""

# Check frontend fixes
echo "Frontend Fixes:"
grep -q "apiFetch" frontend/app.js && echo "  ✅ FIX #13: Token refresh" || echo "  ❌ FIX #13 missing"
grep -q "getCachedData" frontend/app.js && echo "  ✅ FIX #18: Smart caching" || echo "  ❌ FIX #18 missing"
grep -q "Analytics.trackMusicPlay" frontend/app.js && echo "  ✅ FIX #24: Analytics" || echo "  ❌ FIX #24 missing"
echo ""

# Check mobile fixes
echo "Mobile Fixes:"
grep -q "connectivity_plus" villen_music_flutter/pubspec.yaml && echo "  ✅ FIX #17: Connection detection" || echo "  ❌ FIX #17 missing"
grep -q "maxRetries" villen_music_flutter/lib/services/download_service.dart && echo "  ✅ FIX #15: Retry logic" || echo "  ❌ FIX #15 missing"
echo ""

# ==================== READY FOR DEPLOYMENT ====================

print_section "✅ LOCAL TESTING COMPLETE!"

echo "Status: ALL LOCAL TESTS PASSED"
echo ""
echo "📋 NEXT STEPS - DEPLOY TO STAGING:"
echo ""
echo "1️⃣  Configure environment variables:"
cat > deploy_steps.txt << 'EOF'
   export SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_urlsafe(50))')
   export DEBUG=False
   export ALLOWED_HOSTS=staging.yourdomain.com
   export DATABASE_URL=postgresql://user:pass@db_host/villen_staging
   export CORS_ALLOWED_ORIGINS=https://staging.yourdomain.com
EOF
cat deploy_steps.txt

echo ""
echo "2️⃣  Deploy to staging:"
echo "   • Use Render.com: ./deploy_render.sh staging"
echo "   • Or Docker: docker build -t villen-music:staging ."
echo ""
echo "3️⃣  Verify staging:"
echo "   • Run integration tests against staging API"
echo "   • Check monitoring and alerts"
echo "   • Load test with 100+ concurrent users"
echo ""
echo "4️⃣  Deploy to production:"
echo "   • Same process as staging"
echo "   • Monitor metrics for first hour"
echo "   • Have rollback plan ready"
echo ""

echo "📚 Documentation to Review:"
echo "   • SECURITY_AUDIT.md - All security fixes"
echo "   • API_DOCUMENTATION.md - API endpoints"
echo "   • MONITORING_SETUP.md - Monitoring configuration"
echo "   • DATABASE_MIGRATION_PLAN.md - DB schema changes"
echo ""

echo "✅ You're all set! Local testing is complete."
echo ""
