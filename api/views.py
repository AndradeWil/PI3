import uuid

from django.db.models import Sum
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.filters import SearchFilter
from rest_framework.generics import ListAPIView, ListCreateAPIView, RetrieveUpdateAPIView
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken, TokenError

from core.models import Atendimento, Fisioterapeuta, Paciente, Sessao

from .serializers import AtendimentoResumoSerializer, PacienteSerializer, SessaoSerializer


def _fisioterapeuta_do_usuario(user):
    return get_object_or_404(Fisioterapeuta, user=user)


class ApiPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


class PacienteListView(ListCreateAPIView):
    serializer_class = PacienteSerializer
    pagination_class = ApiPagination
    filter_backends = (SearchFilter,)
    search_fields = ('nome', 'telefone', 'email')

    def get_queryset(self):
        fisioterapeuta = _fisioterapeuta_do_usuario(self.request.user)
        return Paciente.objects.filter(fisioterapeuta=fisioterapeuta).select_related('empresa').order_by('nome')

    def perform_create(self, serializer):
        serializer.save(fisioterapeuta=_fisioterapeuta_do_usuario(self.request.user))


class PacienteDetailView(RetrieveUpdateAPIView):
    serializer_class = PacienteSerializer

    def get_queryset(self):
        fisioterapeuta = _fisioterapeuta_do_usuario(self.request.user)
        return Paciente.objects.filter(fisioterapeuta=fisioterapeuta).select_related('empresa')


class SessaoListView(ListAPIView):
    serializer_class = SessaoSerializer
    pagination_class = ApiPagination

    def get_queryset(self):
        fisioterapeuta = _fisioterapeuta_do_usuario(self.request.user)
        queryset = Sessao.objects.filter(
            atendimento__fisioterapeuta=fisioterapeuta,
        ).select_related(
            'atendimento__paciente',
            'atendimento__tipo_atendimento',
        ).order_by('data_hora')
        date_value = self.request.query_params.get('data')
        if not date_value:
            date_value = timezone.localdate().isoformat()
        selected_date = parse_date(date_value)
        if selected_date is None:
            raise ValidationError({'data': ['Use o formato AAAA-MM-DD.']})
        return queryset.filter(data_hora__date=selected_date)


class AtendimentoAtivoListView(ListAPIView):
    serializer_class = AtendimentoResumoSerializer
    pagination_class = None

    def get_queryset(self):
        fisioterapeuta = _fisioterapeuta_do_usuario(self.request.user)
        return Atendimento.objects.filter(
            fisioterapeuta=fisioterapeuta,
            ativo=True,
        ).select_related('paciente', 'tipo_atendimento').order_by('paciente__nome')


class BaterPontoView(APIView):
    def post(self, request, pk):
        fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
        atendimento = get_object_or_404(
            Atendimento,
            pk=pk,
            fisioterapeuta=fisioterapeuta,
            ativo=True,
        )
        key_value = request.headers.get('Idempotency-Key', '')
        try:
            idempotency_key = uuid.UUID(key_value)
        except ValueError:
            raise ValidationError({
                'idempotency_key': ['Envie um UUID valido no cabecalho Idempotency-Key.'],
            })

        session, created = Sessao.objects.get_or_create(
            idempotency_key=idempotency_key,
            defaults={
                'atendimento': atendimento,
                'data_hora': timezone.now(),
                'duracao_minutos': 60,
                'valor_sessao': atendimento.valor_por_sessao,
                'compareceu': True,
                'observacoes': 'Registro rapido pelo aplicativo mobile.',
            },
        )
        if session.atendimento_id != atendimento.id:
            raise ValidationError({'idempotency_key': ['Chave ja utilizada em outro atendimento.']})
        return Response(
            SessaoSerializer(session).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


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