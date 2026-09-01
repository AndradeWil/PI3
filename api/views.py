import uuid
from decimal import Decimal

from django.db.models import ProtectedError, Sum
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.utils.dateparse import parse_date
from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.filters import SearchFilter
from rest_framework.generics import (
    ListAPIView,
    ListCreateAPIView,
    RetrieveUpdateAPIView,
    RetrieveUpdateDestroyAPIView,
)
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken, TokenError
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

from core.models import (
    Atendimento,
    Deslocamento,
    Empresa,
    Fisioterapeuta,
    Glosa,
    Paciente,
    Sessao,
    TipoAtendimento,
)

from .serializers import (
    AtendimentoResumoSerializer,
    AtendimentoSerializer,
    EmpresaSerializer,
    EmpresaOpcaoSerializer,
    PacienteSerializer,
    SessaoSerializer,
    SessaoStatusSerializer,
    TipoAtendimentoOpcaoSerializer,
    TipoAtendimentoSerializer,
)


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


class SessaoDetailView(RetrieveUpdateDestroyAPIView):
    serializer_class = SessaoStatusSerializer

    def get_queryset(self):
        therapist = _fisioterapeuta_do_usuario(self.request.user)
        return Sessao.objects.filter(atendimento__fisioterapeuta=therapist)


class AtendimentoAtivoListView(ListAPIView):
    serializer_class = AtendimentoResumoSerializer
    pagination_class = None

    def get_queryset(self):
        fisioterapeuta = _fisioterapeuta_do_usuario(self.request.user)
        return Atendimento.objects.filter(
            fisioterapeuta=fisioterapeuta,
            ativo=True,
        ).select_related('paciente', 'tipo_atendimento').order_by('paciente__nome')


class AtendimentoListView(ListCreateAPIView):
    serializer_class = AtendimentoSerializer
    pagination_class = ApiPagination

    def get_queryset(self):
        therapist = _fisioterapeuta_do_usuario(self.request.user)
        return Atendimento.objects.filter(fisioterapeuta=therapist).select_related(
            'paciente',
            'empresa',
            'tipo_atendimento',
        ).order_by('-ativo', 'paciente__nome')

    def perform_create(self, serializer):
        serializer.save(fisioterapeuta=_fisioterapeuta_do_usuario(self.request.user))


class AtendimentoDetailView(RetrieveUpdateAPIView):
    serializer_class = AtendimentoSerializer

    def get_queryset(self):
        therapist = _fisioterapeuta_do_usuario(self.request.user)
        return Atendimento.objects.filter(fisioterapeuta=therapist).select_related(
            'paciente',
            'empresa',
            'tipo_atendimento',
        )


class AtendimentoOptionsView(APIView):
    def get(self, request):
        therapist = _fisioterapeuta_do_usuario(request.user)
        return Response({
            'pacientes': [
                {'id': patient.id, 'nome': patient.nome}
                for patient in Paciente.objects.filter(fisioterapeuta=therapist).order_by('nome')
            ],
            'empresas': EmpresaOpcaoSerializer(
                Empresa.objects.filter(fisioterapeuta=therapist).order_by('nome'),
                many=True,
            ).data,
            'tipos_atendimento': TipoAtendimentoOpcaoSerializer(
                TipoAtendimento.objects.filter(fisioterapeuta=therapist).order_by('nome'),
                many=True,
            ).data,
        })


class EmpresaListView(ListCreateAPIView):
    serializer_class = EmpresaSerializer
    pagination_class = ApiPagination

    def get_queryset(self):
        therapist = _fisioterapeuta_do_usuario(self.request.user)
        return Empresa.objects.filter(fisioterapeuta=therapist).order_by('nome')

    def perform_create(self, serializer):
        serializer.save(fisioterapeuta=_fisioterapeuta_do_usuario(self.request.user))


class EmpresaDetailView(RetrieveUpdateDestroyAPIView):
    serializer_class = EmpresaSerializer

    def get_queryset(self):
        therapist = _fisioterapeuta_do_usuario(self.request.user)
        return Empresa.objects.filter(fisioterapeuta=therapist)


class TipoAtendimentoListView(ListCreateAPIView):
    serializer_class = TipoAtendimentoSerializer
    pagination_class = ApiPagination

    def get_queryset(self):
        therapist = _fisioterapeuta_do_usuario(self.request.user)
        return TipoAtendimento.objects.filter(fisioterapeuta=therapist).order_by('nome')

    def perform_create(self, serializer):
        serializer.save(fisioterapeuta=_fisioterapeuta_do_usuario(self.request.user))


class TipoAtendimentoDetailView(RetrieveUpdateDestroyAPIView):
    serializer_class = TipoAtendimentoSerializer

    def get_queryset(self):
        therapist = _fisioterapeuta_do_usuario(self.request.user)
        return TipoAtendimento.objects.filter(fisioterapeuta=therapist)

    def destroy(self, request, *args, **kwargs):
        try:
            return super().destroy(request, *args, **kwargs)
        except ProtectedError:
            return Response(
                {
                    'code': 'protected_resource',
                    'message': 'Tipo vinculado a atendimentos nao pode ser excluido.',
                },
                status=status.HTTP_409_CONFLICT,
            )


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


class FinanceiroResumoView(APIView):
    def get(self, request):
        therapist = _fisioterapeuta_do_usuario(request.user)
        today = timezone.localdate()
        default_start = today.replace(day=1)
        start = self._parse_date(request.query_params.get('data_inicio'), default_start)
        end = self._parse_date(request.query_params.get('data_fim'), today)
        if start > end:
            raise ValidationError({'periodo': ['A data inicial deve ser anterior a data final.']})

        sessions = Sessao.objects.filter(
            atendimento__fisioterapeuta=therapist,
            data_hora__date__gte=start,
            data_hora__date__lte=end,
        ).select_related('atendimento__empresa', 'atendimento__tipo_atendimento')

        total = Decimal('0')
        total_minutes = 0
        by_company = {}
        by_type = {}
        for session in sessions:
            value = session.valor_sessao
            total += value
            total_minutes += session.duracao_minutos
            company = session.atendimento.empresa.nome if session.atendimento.empresa else 'Particular'
            service_type = session.atendimento.tipo_atendimento.nome
            by_company[company] = by_company.get(company, Decimal('0')) + value
            by_type[service_type] = by_type.get(service_type, Decimal('0')) + value

        return Response({
            'data_inicio': start.isoformat(),
            'data_fim': end.isoformat(),
            'total_geral': f'{total:.2f}',
            'total_sessoes': sessions.count(),
            'total_horas': str(round(Decimal(total_minutes) / Decimal('60'), 2)),
            'por_empresa': self._groups(by_company),
            'por_tipo': self._groups(by_type),
        })

    @staticmethod
    def _parse_date(value, default):
        if value is None:
            return default
        parsed = parse_date(value)
        if parsed is None:
            raise ValidationError({'data': ['Use o formato AAAA-MM-DD.']})
        return parsed

    @staticmethod
    def _groups(values):
        return [
            {'nome': name, 'valor': f'{value:.2f}'}
            for name, value in sorted(values.items(), key=lambda item: item[1], reverse=True)
        ]


class RelatorioSessoesView(APIView):
    def get(self, request):
        therapist = _fisioterapeuta_do_usuario(request.user)
        sessions, start, end = self._sessions(request, therapist)
        total_value = sessions.aggregate(total=Sum('valor_sessao')).get('total') or Decimal('0')
        total_minutes = sessions.aggregate(total=Sum('duracao_minutos')).get('total') or 0
        paginator = ApiPagination()
        page = paginator.paginate_queryset(sessions, request, view=self)
        response = paginator.get_paginated_response(SessaoSerializer(page, many=True).data)
        response.data['resumo'] = {
            'data_inicio': start.isoformat(),
            'data_fim': end.isoformat(),
            'total_sessoes': sessions.count(),
            'total_valor': f'{total_value:.2f}',
            'total_horas': str(round(Decimal(total_minutes) / Decimal('60'), 2)),
        }
        return response

    @staticmethod
    def _sessions(request, therapist):
        today = timezone.localdate()
        start = FinanceiroResumoView._parse_date(
            request.query_params.get('data_inicio'),
            today.replace(day=1),
        )
        end = FinanceiroResumoView._parse_date(request.query_params.get('data_fim'), today)
        if start > end:
            raise ValidationError({'periodo': ['A data inicial deve ser anterior a data final.']})
        sessions = Sessao.objects.filter(
            atendimento__fisioterapeuta=therapist,
            data_hora__date__gte=start,
            data_hora__date__lte=end,
        ).select_related(
            'atendimento__paciente',
            'atendimento__empresa',
            'atendimento__tipo_atendimento',
        ).order_by('-data_hora')
        return sessions, start, end


class RelatorioPdfView(APIView):
    def get(self, request):
        therapist = _fisioterapeuta_do_usuario(request.user)
        sessions, start, end = RelatorioSessoesView._sessions(request, therapist)
        response = HttpResponse(content_type='application/pdf')
        response['Content-Disposition'] = (
            f'attachment; filename="relatorio-{start.isoformat()}-{end.isoformat()}.pdf"'
        )
        pdf = canvas.Canvas(response, pagesize=A4)
        _, height = A4
        pdf.setTitle('Relatorio de Atendimentos')
        pdf.setFont('Helvetica-Bold', 14)
        pdf.drawString(40, height - 40, 'Relatorio de Atendimentos')
        pdf.setFont('Helvetica', 9)
        pdf.drawString(40, height - 58, f'Periodo: {start:%d/%m/%Y} a {end:%d/%m/%Y}')
        pdf.drawString(40, height - 72, f'Profissional: {therapist}')
        y = height - 98
        total = Decimal('0')
        for session in sessions:
            if y < 48:
                pdf.showPage()
                pdf.setFont('Helvetica', 8)
                y = height - 40
            local_time = timezone.localtime(session.data_hora)
            company = session.atendimento.empresa.nome if session.atendimento.empresa else 'Particular'
            line = (
                f'{local_time:%d/%m/%Y %H:%M} | '
                f'{session.atendimento.paciente.nome[:24]} | '
                f'{company[:18]} | R$ {session.valor_sessao}'
            )
            pdf.drawString(40, y, line)
            total += session.valor_sessao
            y -= 12
        pdf.setFont('Helvetica-Bold', 10)
        pdf.drawString(40, max(y - 10, 28), f'Total: {sessions.count()} sessoes | R$ {total}')
        pdf.save()
        return response


class InteligenciaDadosView(APIView):
    def get(self, request):
        therapist = _fisioterapeuta_do_usuario(request.user)
        today = timezone.localdate()
        months = [self._shift_month(today.replace(day=1), offset) for offset in range(-5, 1)]
        sessions = Sessao.objects.filter(
            atendimento__fisioterapeuta=therapist,
            data_hora__date__gte=months[0],
            data_hora__date__lt=self._shift_month(months[-1], 1),
        )
        monthly = []
        for month in months:
            next_month = self._shift_month(month, 1)
            month_sessions = sessions.filter(
                data_hora__date__gte=month,
                data_hora__date__lt=next_month,
            )
            revenue = month_sessions.aggregate(total=Sum('valor_sessao')).get('total') or Decimal('0')
            total_count = month_sessions.count()
            absence_count = month_sessions.filter(
                compareceu=False,
                data_hora__lt=timezone.now(),
            ).count()
            monthly.append({
                'mes': month.isoformat(),
                'receita': f'{revenue:.2f}',
                'sessoes': total_count,
                'ausencias': absence_count,
            })

        current = monthly[-1]
        active_patients = Atendimento.objects.filter(
            fisioterapeuta=therapist,
            ativo=True,
        ).values('paciente').distinct().count()
        forecast = self._forecast(monthly)
        elapsed_month_sessions = sessions.filter(
            data_hora__date__gte=months[-1],
            data_hora__lt=timezone.now(),
        )
        absence_rate = (
            round(current['ausencias'] / elapsed_month_sessions.count() * 100, 1)
            if elapsed_month_sessions.exists()
            else 0
        )
        travel = self._travel_summary(therapist, months[0])
        denials = self._denial_summary(therapist, sessions)
        churn = self._churn_summary(therapist)
        return Response({
            'atualizado_em': timezone.now().isoformat(),
            'executivo': {
                'receita_mes': current['receita'],
                'sessoes_mes': current['sessoes'],
                'pacientes_ativos': active_patients,
                'taxa_ausencias': absence_rate,
                'serie_mensal': monthly,
            },
            'previsao_financeira': forecast,
            'custos_deslocamento': travel,
            'glosas': denials,
            'rotatividade': churn,
        })

    @staticmethod
    def _shift_month(value, offset):
        month_index = value.year * 12 + value.month - 1 + offset
        return value.replace(year=month_index // 12, month=month_index % 12 + 1, day=1)

    @staticmethod
    def _forecast(monthly):
        useful = [item for item in monthly if item['sessoes'] > 0]
        if len(useful) < 3:
            return {
                'status': 'dados_insuficientes',
                'motivo': 'Sao necessarios pelo menos tres meses com sessoes.',
            }
        recent = useful[-3:]
        expected = sum(Decimal(item['receita']) for item in recent) / Decimal(len(recent))
        previous = Decimal(recent[-2]['receita'])
        current = Decimal(recent[-1]['receita'])
        trend = round(float((current - previous) / previous * 100), 1) if previous else 0
        return {
            'status': 'disponivel',
            'metodo': 'media_movel_3_meses',
            'receita_proximo_mes': f'{expected:.2f}',
            'tendencia_percentual': trend,
        }

    @staticmethod
    def _travel_summary(therapist, start):
        values = Deslocamento.objects.filter(
            sessao__atendimento__fisioterapeuta=therapist,
            sessao__data_hora__date__gte=start,
        ).aggregate(
            total_cost=Sum('custo'),
            total_distance=Sum('distancia_km'),
        )
        count = Deslocamento.objects.filter(
            sessao__atendimento__fisioterapeuta=therapist,
            sessao__data_hora__date__gte=start,
        ).count()
        if not count:
            return {
                'status': 'dados_insuficientes',
                'motivo': 'Custos de deslocamento ainda nao sao registrados.',
            }
        total_cost = values['total_cost'] or Decimal('0')
        return {
            'status': 'disponivel',
            'registros': count,
            'distancia_total_km': f"{values['total_distance'] or Decimal('0'):.2f}",
            'custo_total': f'{total_cost:.2f}',
            'custo_medio_sessao': f'{total_cost / count:.2f}',
        }

    @staticmethod
    def _denial_summary(therapist, sessions):
        denials = Glosa.objects.filter(
            sessao__atendimento__fisioterapeuta=therapist,
        ).exclude(status='revertida')
        if not denials.exists():
            return {
                'status': 'dados_insuficientes',
                'motivo': 'Historico de glosas ainda nao esta disponivel.',
            }
        total_value = denials.aggregate(total=Sum('valor')).get('total') or Decimal('0')
        affected_sessions = denials.values('sessao').distinct().count()
        session_count = sessions.count()
        operator = (
            denials.values('operadora')
            .annotate(total=Sum('valor'))
            .order_by('-total')
            .first()
        )
        return {
            'status': 'disponivel',
            'quantidade': denials.count(),
            'pendentes': denials.filter(status='pendente').count(),
            'valor_total': f'{total_value:.2f}',
            'taxa_percentual': round(affected_sessions / session_count * 100, 1) if session_count else 0,
            'principal_operadora': operator['operadora'] if operator else '',
        }

    @staticmethod
    def _churn_summary(therapist):
        now = timezone.now()
        risks = []
        appointments = Atendimento.objects.filter(
            fisioterapeuta=therapist,
            ativo=True,
        ).select_related('paciente')
        for appointment in appointments:
            past = appointment.sessoes.filter(data_hora__lt=now).order_by('-data_hora')
            last = past.first()
            if last is None:
                score = 80
                reason = 'Nenhuma sessao realizada no historico.'
            else:
                days = (timezone.localdate() - timezone.localtime(last.data_hora).date()).days
                recency_score = 50 if days > 30 else 30 if days > 14 else 10
                recent = list(past[:5])
                absences = sum(not session.compareceu for session in recent)
                score = min(95, recency_score + round(absences / len(recent) * 40))
                reason = f'Ultima sessao ha {days} dias; {absences} falta(s) nas ultimas {len(recent)}.'
            risks.append({
                'paciente_id': appointment.paciente_id,
                'paciente_nome': appointment.paciente.nome,
                'risco_percentual': score,
                'nivel': 'alto' if score >= 70 else 'moderado' if score >= 40 else 'baixo',
                'fator_principal': reason,
            })
        risks.sort(key=lambda item: item['risco_percentual'], reverse=True)
        if not risks:
            return {
                'status': 'dados_insuficientes',
                'motivo': 'Nao ha pacientes ativos para avaliar.',
            }
        return {
            'status': 'disponivel',
            'metodo': 'heuristica_recencia_faltas',
            'aviso': 'Indicador administrativo demonstrativo; nao e um modelo clinico validado.',
            'pacientes_em_risco': sum(item['nivel'] != 'baixo' for item in risks),
            'ranking': risks[:5],
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