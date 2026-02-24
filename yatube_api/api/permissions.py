from rest_framework import permissions

class IsAuthorOrReadOnly(permissions.BasePermission):
    """
    Разрешает редактирование только автору объекта.
    Чтение — всем (SAFE_METHODS).
    """
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return getattr(obj, 'author', None) == request.user