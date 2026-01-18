from django.contrib.auth.models import User
from rest_framework import serializers
from ..models import LikedSong

class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ('username', 'password', 'email')

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password'],
            email=validated_data.get('email', '')
        )
        return user

class LikedSongSerializer(serializers.ModelSerializer):
    class Meta:
        model = LikedSong
        fields = ['song_id', 'title', 'artist', 'image', 'duration', 'created_at']
        extra_kwargs = {
            'song_id': {'validators': []}  # We handle uniqueness manually/via UniqueTogether
        }
