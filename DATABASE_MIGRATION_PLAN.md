# VILLEN Music - Database Migration Plan

## Overview

This document outlines the database migration strategy for VILLEN Music, covering schema evolution, data migrations, and deployment procedures.

**Current Database:** SQLite (Development) / PostgreSQL (Production)
**Current Schema Version:** 1.0.0

---

## Migration Workflow

### 1. Development Phase

#### Step 1: Create Migration
```bash
cd backend
python manage.py makemigrations music
```

This creates a new migration file in `music/migrations/` automatically detecting changes.

#### Step 2: Review Migration
```bash
cat music/migrations/000X_description.py
```

Verify the migration:
- ✅ Field additions
- ✅ Field removals
- ✅ Type changes
- ✅ Index changes

#### Step 3: Test Locally
```bash
python manage.py migrate
python manage.py test
```

Verify all tests pass and no data is lost.

---

### 2. Staging Phase

**Environment:** Pre-production database with production-like data volume

```bash
# Backup staging database
pg_dump villen_staging > backups/staging_$(date +%Y%m%d_%H%M%S).sql

# Apply migration
python manage.py migrate --database=staging

# Verify data integrity
python manage.py shell < verify_migration.py

# Run full test suite
python manage.py test --database=staging
```

---

### 3. Production Deployment

#### Pre-Migration Checklist

- [ ] All team members reviewed the migration
- [ ] Tests pass on staging database
- [ ] Backup taken of production database
- [ ] Maintenance window scheduled (off-peak hours)
- [ ] Rollback procedure documented
- [ ] Communication sent to users about potential downtime

#### Migration Script

```bash
#!/bin/bash
set -e

DATABASE_URL="postgresql://user:pass@prod-db/villen"
BACKUP_FILE="backups/prod_$(date +%Y%m%d_%H%M%S).sql"

echo "🔄 Starting migration..."

# Step 1: Backup
echo "📦 Backing up database..."
pg_dump $DATABASE_URL > $BACKUP_FILE
echo "✅ Backup saved: $BACKUP_FILE"

# Step 2: Apply migration
echo "🚀 Applying migration..."
python manage.py migrate --settings=core.settings.production

# Step 3: Verify
echo "✔️ Verifying migration..."
python manage.py check
python manage.py shell < verify_migration.py

echo "✅ Migration complete!"
```

---

## Planned Migrations (v1 → v2)

### Migration 1: User Preferences (v1.1)
**Status:** Planned for Q2 2024

**Changes:**
- Add `User.preferred_language` field
- Add `User.audio_quality` field
- Add `User.theme_preference` field

**Steps:**
```python
# 001_add_user_preferences.py
from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ('music', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='preferred_language',
            field=models.CharField(
                max_length=10,
                choices=[('hi', 'Hindi'), ('en', 'English')],
                default='en'
            ),
        ),
        migrations.AddField(
            model_name='user',
            name='audio_quality',
            field=models.CharField(
                max_length=10,
                choices=[('128', '128 kbps'), ('192', '192 kbps'), ('320', '320 kbps')],
                default='192'
            ),
        ),
        migrations.AddField(
            model_name='user',
            name='theme_preference',
            field=models.CharField(max_length=50, default='dark'),
        ),
        # Add index for frequently queried field
        migrations.AddIndex(
            model_name='user',
            index=models.Index(
                fields=['preferred_language'],
                name='user_lang_idx',
            ),
        ),
    ]
```

**Data Migration:** None required (defaults applied automatically)
**Rollback:** `python manage.py migrate music 0001_initial`

---

### Migration 2: Playlist Support (v1.2)
**Status:** Planned for Q3 2024

**New Models:**
```python
class Playlist(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    songs = models.ManyToManyField(Song)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_public = models.BooleanField(default=False)
```

**Migration Steps:**
1. Create Playlist model
2. Create PlaylistSong through table
3. Index on user + is_public for faster queries

---

### Migration 3: Analytics Tables (v1.3)
**Status:** Planned for Q4 2024

**New Models:**
```python
class AnalyticsEvent(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True)
    event_type = models.CharField(max_length=50)
    song = models.ForeignKey(Song, on_delete=models.SET_NULL, null=True)
    properties = models.JSONField(default=dict)
    timestamp = models.DateTimeField(auto_now_add=True)
    session_id = models.CharField(max_length=100)
    
    class Meta:
        indexes = [
            models.Index(fields=['timestamp', 'user']),
            models.Index(fields=['event_type']),
        ]
```

---

## Data Backup Strategy

### Automated Backups

**Schedule:** Daily at 2 AM UTC (off-peak)

```bash
# Cron job
0 2 * * * /opt/villen/backup_database.sh

# Script content
#!/bin/bash
DATE=$(date +\%Y\%m\%d_\%H\%M\%S)
pg_dump $DATABASE_URL | gzip > /backups/villen_$DATE.sql.gz
# Keep last 30 days
find /backups -name "villen_*.sql.gz" -mtime +30 -delete
```

### Retention Policy

| Backup Type | Retention |
|-------------|-----------|
| Daily | 7 days |
| Weekly | 4 weeks |
| Monthly | 12 months |
| Pre-migration | Indefinite |

---

## Rollback Procedure

**Time to Rollback:** < 5 minutes

### Step 1: Identify Issue
If migration causes problems:
```bash
# Check application logs
journalctl -u villen-api -n 100

# Monitor database
psql $DATABASE_URL -c "SELECT pid, query FROM pg_stat_activity;"
```

### Step 2: Rollback Migration
```bash
python manage.py migrate music <previous_version>
```

Example:
```bash
# Roll back from 0005 to 0004
python manage.py migrate music 0004
```

### Step 3: Restore from Backup (if needed)
```bash
# List backups
ls -lh /backups/

# Restore
pg_restore -U postgres -d villen /backups/prod_20240115_020000.sql.gz
```

---

## Testing Migrations

### Unit Tests

```python
# music/tests/test_migrations.py

from django.test import TestCase
from django.db import connection
from django.db.migrations.executor import MigrationExecutor

class MigrationTests(TestCase):
    def test_migration_0001(self):
        """Test that migration 0001 applies correctly"""
        executor = MigrationExecutor(connection)
        
        # Apply migration
        executor.migrate([('music', '0001_initial')])
        
        # Verify schema
        self.assertTrue('music_song' in connection.introspection.table_names())
        self.assertTrue('music_user' in connection.introspection.table_names())
```

### Performance Tests

Before production migration:

```python
# Measure query performance
import time
from django.test.utils import override_settings

@override_settings(DEBUG=True)
def test_query_performance():
    from django.db import connection
    from django.test.utils import CaptureQueriesContext
    
    with CaptureQueriesContext(connection) as queries:
        Song.objects.filter(language='hindi').count()
    
    # Should use index, < 100ms
    assert queries[0]['time'] < 0.1
```

---

## Monitoring Post-Migration

### Health Checks

```bash
#!/bin/bash

# Database connectivity
psql $DATABASE_URL -c "SELECT 1;" || echo "❌ DB unreachable"

# Check query performance
psql $DATABASE_URL -c "EXPLAIN ANALYZE SELECT * FROM music_song LIMIT 1;"

# Monitor slow queries
psql $DATABASE_URL -c "SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;"
```

### Metrics to Monitor

- **Query Response Time:** Target < 200ms p95
- **Connection Pool:** Target < 80% utilization
- **Lock Wait Time:** Target < 10ms p95
- **Disk Usage:** Alert if > 80%

---

## Common Issues & Solutions

### Issue 1: Migration Hangs
**Symptom:** Migration running for > 5 minutes
**Solution:**
```bash
# Check blocking queries
psql $DATABASE_URL -c "SELECT pid, pg_blocking_pids(pid), query FROM pg_stat_activity WHERE pg_blocking_pids(pid)::text != '{}';"

# Kill blocking process
SELECT pg_terminate_backend(pid);

# Restart migration
python manage.py migrate
```

### Issue 2: Disk Space Exceeded
**Symptom:** "No space left on device"
**Solution:**
```bash
# Check disk usage
df -h

# Clean up old migrations (after verified backup)
find . -path "*/migrations/*.pyc" -delete
find . -path "*/migrations/__pycache__" -type d -exec rm -rf {} +

# Archive old backups
tar czf backups_archive_2023.tar.gz backups/prod_2023*
```

### Issue 3: Foreign Key Constraint Violation
**Symptom:** Migration fails with FK constraint error
**Solution:**
```bash
# Temporarily disable FK checks (SQLite only)
PRAGMA foreign_keys = OFF;

# Or for PostgreSQL, defer constraints
SET CONSTRAINTS ALL DEFERRED;

# Then retry migration
python manage.py migrate
```

---

## Documentation & Communication

### Pre-Migration Communication

**Email to Users:**
```
Subject: Scheduled Maintenance - VILLEN Music

Dear Users,

We're upgrading our database on [DATE] from [TIME] to [TIME] UTC.

During this time:
- The app may be unavailable for up to 30 minutes
- Your data is safe (full backup taken)
- No action needed from you

Thank you for your patience!
- VILLEN Team
```

### Post-Migration Report

Document all migrations in `MIGRATIONS.md`:

```markdown
## Migration 0005: Add Playlist Support
- **Date:** 2024-01-15
- **Duration:** 2 minutes 15 seconds
- **Downtime:** None (online migration)
- **Data Changes:** None
- **New Tables:** playlist, playlist_songs
- **Tested:** ✅ All tests passing
- **Status:** ✅ Deployed to production
```

---

## Tools & References

- **Django Migrations:** https://docs.djangoproject.com/en/4.2/topics/migrations/
- **PostgreSQL:** https://www.postgresql.org/docs/current/
- **Backup Tools:** `pg_dump`, `pg_restore`
- **Monitoring:** pgAdmin, Datadog, New Relic

---

**Last Updated:** 2024-01-15
**Database Version:** 1.0.0
