from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from . import views
from rest_framework.routers import DefaultRouter

router = DefaultRouter()
router.register(r'playlists', views.PlaylistViewSet, basename='playlist')


urlpatterns = [
    # Search
    path("search/", views.search_songs, name="search_songs"),
    
    # Song endpoints
    path("stream/<str:song_id>/", views.stream_song, name="stream_song"),
    path("song/<str:song_id>/", views.song_details, name="song_details"),
    path("song/<str:song_id>/lyrics/", views.song_lyrics, name="song_lyrics"),
    path("song/<str:song_id>/related/", views.song_related, name="song_related"),
    
    # Album & Artist
    path("album/<str:album_id>/", views.album_details, name="album_details"),
    path("artist/<str:artist_id>/", views.artist_details, name="artist_details"),
    
    # Discovery
    path("trending/", views.trending_songs, name="trending_songs"),
    
    # Debug
    path("cache/stats/", views.cache_stats, name="cache_stats"),
    path("csrf/", views.get_csrf_token, name="csrf"),

    # Auth & Sync
    path("auth/register/", views.RegisterView.as_view(), name="register"),
    path("auth/login/", views.CustomTokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("auth/logout/", views.LogoutView.as_view(), name="logout"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),  # FIX #13

    # Social Features
    path("user/profile/", views.UserProfileView.as_view(), name="user_profile"),
    path("user/following/", views.FollowArtistView.as_view(), name="user_following"),
    path("user/activity/", views.ActivityFeedView.as_view(), name="user_activity"),
    
    # Personalization
    path("history/record/", views.RecordHistoryView.as_view(), name="record_history"),
    path("discover/weekly/", views.DiscoverWeeklyView.as_view(), name="discover_weekly"),
    path("discover/monthly/", views.DiscoverWeeklyView.as_view(), name="discover_monthly"), # Alias
    path("browse/charts/", views.ChartsView.as_view(), name="browse_charts"),
    path("discover/mood/", views.MoodPlaylistView.as_view(), name="mood_playlist"),
    path("discover/artists/suggested/", views.SuggestedArtistsView.as_view(), name="suggested_artists"),

    path("discover/time/", views.TimeAwarePlaylistView.as_view(), name="time_playlist"),
    path("user/insights/", views.UserInsightsView.as_view(), name="user_insights"),
] + router.urls


