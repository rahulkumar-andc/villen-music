from django.urls import path
from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from . import views

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

    # Auth & Sync
    path("auth/register/", views.RegisterView.as_view(), name="register"),
    path("auth/login/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("user/likes/", views.ManageLikesView.as_view(), name="manage_likes"),
]
