from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .views import AtendimentoAtivoListView, AtendimentoDetailView, AtendimentoListView, AtendimentoOptionsView, BaterPontoView, DashboardView, LogoutView, MeView, PacienteDetailView, PacienteListView, SessaoListView

urlpatterns = [
    path('auth/token/', TokenObtainPairView.as_view(), name='api_token'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='api_token_refresh'),
    path('auth/logout/', LogoutView.as_view(), name='api_logout'),
    path('me/', MeView.as_view(), name='api_me'),
    path('dashboard/', DashboardView.as_view(), name='api_dashboard'),
    path('pacientes/', PacienteListView.as_view(), name='api_pacientes'),
    path('pacientes/<int:pk>/', PacienteDetailView.as_view(), name='api_paciente_detail'),
    path('sessoes/', SessaoListView.as_view(), name='api_sessoes'),
    path('atendimentos/ativos/', AtendimentoAtivoListView.as_view(), name='api_atendimentos_ativos'),
    path('atendimentos/opcoes/', AtendimentoOptionsView.as_view(), name='api_atendimentos_opcoes'),
    path('atendimentos/', AtendimentoListView.as_view(), name='api_atendimentos'),
    path('atendimentos/<int:pk>/', AtendimentoDetailView.as_view(), name='api_atendimento_detail'),
    path('atendimentos/<int:pk>/bater-ponto/', BaterPontoView.as_view(), name='api_bater_ponto'),
]