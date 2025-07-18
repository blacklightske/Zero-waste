from django.urls import path
from .views import (
    RegisterView,
    LoginView,
    LogoutView,
    UserProfileView,
    PasswordResetView,
    PasswordChangeView,
    user_profile
)

app_name = 'accounts'

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('profile/', UserProfileView.as_view(), name='profile'),
    path('me/', user_profile, name='user_profile'),
    path('password-reset/', PasswordResetView.as_view(), name='password_reset'),
    path('password-change/', PasswordChangeView.as_view(), name='password_change'),
]