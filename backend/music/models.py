from django.db import models
from django.contrib.auth.models import User
from django.conf import settings
from django.db.models.signals import post_save
from django.dispatch import receiver


class LikedSong(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='liked_songs')
    song_id = models.CharField(max_length=100)
    title = models.CharField(max_length=255)
    artist = models.CharField(max_length=255)
    image = models.URLField(max_length=500, blank=True, null=True)
    duration = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'song_id')
        indexes = [
            models.Index(fields=['user', '-created_at']),
        ]

    def __str__(self):
        return f"{self.user.username} - {self.title}"


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    bio = models.TextField(max_length=500, blank=True)
    avatar_url = models.URLField(max_length=500, blank=True, null=True)
    is_public = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.user.username

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.profile.save()


class FollowedArtist(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='following')
    artist_id = models.CharField(max_length=100)
    artist_name = models.CharField(max_length=255)
    artist_image = models.URLField(max_length=500, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'artist_id')
        indexes = [
            models.Index(fields=['user', '-created_at']),
        ]

    def __str__(self):
        return f"{self.user.username} -> {self.artist_name}"


class Playlist(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='playlists')
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    is_public = models.BooleanField(default=True)
    collaborators = models.ManyToManyField(User, related_name='collaborating_playlists', blank=True)
    image = models.URLField(max_length=500, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class PlaylistSong(models.Model):
    playlist = models.ForeignKey(Playlist, on_delete=models.CASCADE, related_name='songs')
    song_id = models.CharField(max_length=100)
    title = models.CharField(max_length=255)
    artist = models.CharField(max_length=255)
    image = models.URLField(max_length=500, blank=True, null=True)
    duration = models.IntegerField(default=0)
    added_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    added_at = models.DateTimeField(auto_now_add=True)
    order = models.IntegerField(default=0)

    class Meta:
        ordering = ['order', 'added_at']

    def __str__(self):
        return f"{self.playlist.name} - {self.title}"


class Activity(models.Model):
    ACTION_TYPES = (
        ('FOLLOW', 'Followed Artist'),
        ('LIKE', 'Liked Song'),
        ('PLAYLIST_CREATE', 'Created Playlist'),
        ('PLAYLIST_ADD', 'Added to Playlist'),
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='activities')
    action_type = models.CharField(max_length=20, choices=ACTION_TYPES)
    target_id = models.CharField(max_length=100)  # ID of song, artist, playlist, etc.
    description = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['-created_at']),
            models.Index(fields=['user', '-created_at']),
        ]
        verbose_name_plural = "Activities"

    def __str__(self):
        return f"{self.user.username} {self.action_type}"


class PlaybackHistory(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='playback_history')
    song_id = models.CharField(max_length=100)
    title = models.CharField(max_length=255, blank=True, default='')
    artist = models.CharField(max_length=255, blank=True, default='')
    duration = models.IntegerField(default=0)  # Duration in seconds
    listened_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=['user', '-listened_at']),
        ]
        verbose_name_plural = "Playback Histories"

    def __str__(self):
        return f"{self.user.username} - {self.song_id}"


# =============================================================================
# SOCIAL FEATURES - Friends & Activity Sharing
# =============================================================================

class FriendFollow(models.Model):
    """Track friend relationships between users."""
    follower = models.ForeignKey(User, on_delete=models.CASCADE, related_name='following_friends')
    following = models.ForeignKey(User, on_delete=models.CASCADE, related_name='friend_followers')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('follower', 'following')
        indexes = [
            models.Index(fields=['follower', '-created_at']),
            models.Index(fields=['following', '-created_at']),
        ]

    def __str__(self):
        return f"{self.follower.username} -> {self.following.username}"


class CurrentlyPlaying(models.Model):
    """Store what users are currently playing - real-time status."""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='currently_playing')
    song_id = models.CharField(max_length=100)
    title = models.CharField(max_length=255)
    artist = models.CharField(max_length=255)
    image = models.URLField(max_length=500, blank=True, null=True)
    started_at = models.DateTimeField(auto_now=True)
    is_playing = models.BooleanField(default=True)

    class Meta:
        verbose_name_plural = "Currently Playing"

    def __str__(self):
        status = "▶️" if self.is_playing else "⏸️"
        return f"{status} {self.user.username}: {self.title}"


# =============================================================================
# SYNCED LYRICS - Karaoke Mode
# =============================================================================

class SyncedLyrics(models.Model):
    """Store line-by-line lyrics with timestamps (LRC format)."""
    song_id = models.CharField(max_length=100, unique=True, db_index=True)
    lrc_content = models.TextField(help_text="LRC format lyrics with timestamps")
    source = models.CharField(max_length=50, default='jiosaavn')  # Source API
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = "Synced Lyrics"

    def __str__(self):
        return f"Lyrics: {self.song_id}"


# =============================================================================
# ENHANCED INSIGHTS - Wrapped-Style Statistics
# =============================================================================

class ListeningStreak(models.Model):
    """Track daily listening streaks for gamification."""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='listening_streak')
    current_streak = models.IntegerField(default=0)
    longest_streak = models.IntegerField(default=0)
    last_listen_date = models.DateField(null=True, blank=True)
    total_days_listened = models.IntegerField(default=0)

    def __str__(self):
        return f"{self.user.username}: {self.current_streak} days"

    def update_streak(self):
        """Call this when user plays a song."""
        from django.utils import timezone
        today = timezone.now().date()
        
        if self.last_listen_date is None:
            self.current_streak = 1
        elif self.last_listen_date == today:
            pass  # Already listened today
        elif self.last_listen_date == today - timezone.timedelta(days=1):
            self.current_streak += 1
        else:
            self.current_streak = 1  # Streak broken
        
        self.last_listen_date = today
        self.total_days_listened += 1
        self.longest_streak = max(self.longest_streak, self.current_streak)
        self.save()


class MonthlyStats(models.Model):
    """Pre-computed monthly listening statistics for performance."""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='monthly_stats')
    year = models.IntegerField()
    month = models.IntegerField()  # 1-12
    
    # Aggregated stats
    total_minutes = models.IntegerField(default=0)
    total_songs = models.IntegerField(default=0)
    unique_artists = models.IntegerField(default=0)
    
    # Top items (stored as JSON)
    top_songs = models.JSONField(default=list)  # [{song_id, title, count}, ...]
    top_artists = models.JSONField(default=list)  # [{name, count}, ...]
    genre_distribution = models.JSONField(default=dict)  # {genre: percentage, ...}
    
    # Listening patterns
    hourly_distribution = models.JSONField(default=list)  # [count for hour 0-23]
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'year', 'month')
        indexes = [
            models.Index(fields=['user', '-year', '-month']),
        ]
        verbose_name_plural = "Monthly Stats"

    def __str__(self):
        return f"{self.user.username} - {self.year}/{self.month}"


