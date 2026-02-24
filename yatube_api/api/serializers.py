from rest_framework import serializers
from posts.models import Post, Group, Comment
from django.contrib.auth import get_user_model

User = get_user_model()

class GroupSerializer(serializers.ModelSerializer):
    class Meta:
        model = Group
        fields = ('id', 'title', 'slug', 'description')


class PostSerializer(serializers.ModelSerializer):
    author = serializers.SlugRelatedField(
        read_only=True, slug_field='username'
    )
    group = serializers.PrimaryKeyRelatedField(
        queryset=Group.objects.all(), required=False, allow_null=True
    )
    image = serializers.ImageField(required=False, allow_null=True)

    class Meta:
        model = Post
        fields = ('id', 'text', 'pub_date', 'author', 'group', 'image')
        read_only_fields = ('id', 'pub_date', 'author')


class CommentSerializer(serializers.ModelSerializer):
    author = serializers.SlugRelatedField(read_only=True, slug_field='username')
    post = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Comment
        fields = ('id', 'author', 'post', 'text', 'created')
        read_only_fields = ('id', 'author', 'post', 'created')