from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .views import DashboardView, LogoutView, MeView

urlpatterns = [
    path('auth/token/', TokenObtainPairView.as_view(), name='api_token'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='api_token_refresh'),
    path('auth/logout/', LogoutView.as_view(), name='api_logout'),
    path('me/', MeView.as_view(), name='api_me'),
    path('dashboard/', DashboardView.as_view(), name='api_dashboard'),
]