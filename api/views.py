from django.db.models import Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken, TokenError

from core.models import Atendimento, Fisioterapeuta, Sessao


def _fisioterapeuta_do_usuario(user):
    return get_object_or_404(Fisioterapeuta, user=user)


class MeView(APIView):
    def get(self, request):
        fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
        return Response({
            'id': fisioterapeuta.id,
            'username': request.user.username,
            'name': request.user.get_full_name() or request.user.username,
            'email': request.user.email,
            'crefito': fisioterapeuta.crefito,
            'phone': fisioterapeuta.telefone,
        })


class DashboardView(APIView):
    def get(self, request):
        fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
        now = timezone.localtime()
        today = now.date()
        atendimentos = Atendimento.objects.filter(fisioterapeuta=fisioterapeuta)
        sessoes = Sessao.objects.filter(
            atendimento__fisioterapeuta=fisioterapeuta,
        ).select_related('atendimento__paciente')

        monthly_revenue = (
            sessoes.filter(data_hora__year=now.year, data_hora__month=now.month)
            .aggregate(total=Sum('valor_sessao'))
            .get('total')
            or 0
        )
        today_agenda = sessoes.filter(data_hora__date=today).order_by('data_hora')
        next_session = sessoes.filter(data_hora__gte=now).order_by('data_hora').first()

        return Response({
            'monthly_revenue': str(monthly_revenue),
            'active_patients': atendimentos.filter(ativo=True).values('paciente').distinct().count(),
            'today_sessions': today_agenda.count(),
            'alerts': 0,
            'next_session': self._session_data(next_session),
            'today_agenda': [self._session_data(session) for session in today_agenda[:20]],
        })

    @staticmethod
    def _session_data(session):
        if session is None:
            return None
        return {
            'id': session.id,
            'time': timezone.localtime(session.data_hora).strftime('%H:%M'),
            'patient_name': session.atendimento.paciente.nome,
            'location': session.atendimento.paciente.endereco,
            'attended': session.compareceu,
        }


class LogoutView(APIView):
    def post(self, request):
        refresh = request.data.get('refresh')
        if not refresh:
            return Response(
                {'code': 'validation_error', 'message': 'Informe o refresh token.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            RefreshToken(refresh).blacklist()
        except TokenError:
            return Response(
                {'code': 'invalid_token', 'message': 'Refresh token invalido.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        return Response(status=status.HTTP_204_NO_CONTENT)