from rest_framework import serializers
from django.contrib.auth.models import User
from music.models import (
    UserProfile, FollowedArtist, Playlist, PlaylistSong, Activity,
    FriendFollow, CurrentlyPlaying, ListeningStreak, MonthlyStats
)

class UserProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.EmailField(source='user.email', read_only=True)

    class Meta:
        model = UserProfile
        fields = ['id', 'username', 'email', 'bio', 'avatar_url', 'is_public', 'created_at']

class FollowedArtistSerializer(serializers.ModelSerializer):
    class Meta:
        model = FollowedArtist
        fields = ['id', 'artist_id', 'artist_name', 'artist_image', 'created_at']

class PlaylistSongSerializer(serializers.ModelSerializer):
    added_by_username = serializers.CharField(source='added_by.username', read_only=True)

    class Meta:
        model = PlaylistSong
        fields = ['id', 'song_id', 'title', 'artist', 'image', 'duration', 'added_by', 'added_by_username', 'added_at', 'order']

class PlaylistSerializer(serializers.ModelSerializer):
    owner = serializers.CharField(source='user.username', read_only=True)
    songs = PlaylistSongSerializer(many=True, read_only=True)
    collaborators_count = serializers.IntegerField(source='collaborators.count', read_only=True)
    is_owner = serializers.SerializerMethodField()
    is_collaborator = serializers.SerializerMethodField()

    class Meta:
        model = Playlist
        fields = ['id', 'owner', 'name', 'description', 'is_public', 'image', 'songs', 'created_at', 'updated_at', 'collaborators_count', 'is_owner', 'is_collaborator']

    def get_is_owner(self, obj):
        request = self.context.get('request')
        return request and request.user == obj.user

    def get_is_collaborator(self, obj):
        request = self.context.get('request')
        return request and request.user in obj.collaborators.all()

class ActivitySerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    user_avatar = serializers.URLField(source='user.profile.avatar_url', read_only=True)

    class Meta:
        model = Activity
        fields = ['id', 'username', 'user_avatar', 'action_type', 'target_id', 'description', 'created_at']


# =============================================================================
# NEW SERIALIZERS - Social Features & Insights
# =============================================================================

class FriendSerializer(serializers.ModelSerializer):
    """Serializer for friend relationships."""
    username = serializers.CharField(source='following.username', read_only=True)
    avatar_url = serializers.SerializerMethodField()
    currently_playing = serializers.SerializerMethodField()

    class Meta:
        model = FriendFollow
        fields = ['id', 'username', 'avatar_url', 'currently_playing', 'created_at']

    def get_avatar_url(self, obj):
        try:
            return obj.following.profile.avatar_url
        except:
            return None

    def get_currently_playing(self, obj):
        try:
            playing = obj.following.currently_playing
            if playing and playing.is_playing:
                return {
                    'song_id': playing.song_id,
                    'title': playing.title,
                    'artist': playing.artist,
                    'image': playing.image,
                }
        except CurrentlyPlaying.DoesNotExist:
            pass
        return None


class CurrentlyPlayingSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    
    class Meta:
        model = CurrentlyPlaying
        fields = ['song_id', 'title', 'artist', 'image', 'is_playing', 'started_at', 'username']
        read_only_fields = ['started_at', 'username']


class ListeningStreakSerializer(serializers.ModelSerializer):
    class Meta:
        model = ListeningStreak
        fields = ['current_streak', 'longest_streak', 'last_listen_date', 'total_days_listened']


class MonthlyStatsSerializer(serializers.ModelSerializer):
    class Meta:
        model = MonthlyStats
        fields = [
            'year', 'month', 'total_minutes', 'total_songs', 'unique_artists',
            'top_songs', 'top_artists', 'genre_distribution', 'hourly_distribution'
        ]
