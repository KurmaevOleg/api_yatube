from rest_framework import viewsets, permissions
from rest_framework.authentication import TokenAuthentication
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404

from posts.models import Post, Group, Comment
from .serializers import PostSerializer, GroupSerializer, CommentSerializer
from .permissions import IsAuthorOrReadOnly

class PostViewSet(viewsets.ModelViewSet):
    """
    Обязательно ModelViewSet для Post.
    Доступность:
     - создать/редактировать/удалять — только автор (аутентифицированный).
     - просматривать — всем.
    """
    queryset = Post.objects.all()
    serializer_class = PostSerializer
    authentication_classes = (TokenAuthentication,)
    permission_classes = (permissions.IsAuthenticatedOrReadOnly, IsAuthorOrReadOnly)

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)


class GroupViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Только чтение групп.
    """
    queryset = Group.objects.all()
    serializer_class = GroupSerializer
    authentication_classes = (TokenAuthentication,)
    permission_classes = (permissions.IsAuthenticatedOrReadOnly,)


class CommentViewSet(viewsets.ModelViewSet):
    """
    ViewSet для работы с комментариями конкретного поста.
    URL-шаблон использует post_id в пути.
    """
    serializer_class = CommentSerializer
    authentication_classes = (TokenAuthentication,)
    permission_classes = (permissions.IsAuthenticatedOrReadOnly, IsAuthorOrReadOnly)

    def get_queryset(self):
        post_id = self.kwargs.get('post_id')
        post = get_object_or_404(Post, pk=post_id)
        return post.comments.all()

    def perform_create(self, serializer):
        post_id = self.kwargs.get('post_id')
        post = get_object_or_404(Post, pk=post_id)
        serializer.save(author=self.request.user, post=post)