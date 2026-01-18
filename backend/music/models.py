from django.db import models
from django.contrib.auth.models import User

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
