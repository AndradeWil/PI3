import os
from datetime import datetime, time, timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

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


class Command(BaseCommand):
    help = 'Cria um fisioterapeuta padrao e uma massa idempotente para demonstracao.'

    @transaction.atomic
    def handle(self, *args, **options):
        username = os.getenv('DJANGO_DEMO_USERNAME', '').strip()
        email = os.getenv('DJANGO_DEMO_EMAIL', '').strip()
        password = os.getenv('DJANGO_DEMO_PASSWORD', '')
        if not username or not email or not password:
            self.stdout.write('Usuario demo nao configurado; variaveis de ambiente ausentes.')
            return

        user_model = get_user_model()
        user, _ = user_model.objects.get_or_create(username=username)
        user.email = email
        user.first_name = 'Fisioterapeuta'
        user.last_name = 'Demonstracao'
        user.is_active = True
        user.set_password(password)
        user.save()

        therapist, _ = Fisioterapeuta.objects.update_or_create(
            user=user,
            defaults={
                'crefito': 'CREFITO-DEMO',
                'telefone': '(11) 99999-0000',
                'cpf': '',
            },
        )
        company, _ = Empresa.objects.update_or_create(
            fisioterapeuta=therapist,
            nome='Saude em Casa Demo',
            defaults={
                'contato': 'Central de Atendimento',
                'telefone': '(11) 4000-1000',
                'email': 'contato@demo.invalid',
            },
        )
        motor, _ = TipoAtendimento.objects.update_or_create(
            fisioterapeuta=therapist,
            nome='Fisioterapia Motora',
            defaults={
                'descricao': 'Atendimento domiciliar para reabilitacao motora.',
                'valor_padrao': Decimal('120.00'),
            },
        )
        respiratory, _ = TipoAtendimento.objects.update_or_create(
            fisioterapeuta=therapist,
            nome='Fisioterapia Respiratoria',
            defaults={
                'descricao': 'Atendimento respiratorio domiciliar.',
                'valor_padrao': Decimal('150.00'),
            },
        )

        patients = [
            ('Ana Martins', 67, 'Vila Mariana', 'Pos-operatorio de joelho', motor, Decimal('120.00')),
            ('Carlos Oliveira', 74, 'Moema', 'Reabilitacao respiratoria', respiratory, Decimal('150.00')),
            ('Marina Souza', 52, 'Saude', 'Fortalecimento e equilibrio', motor, Decimal('130.00')),
            ('Paulo Santos', 81, 'Ipiranga', 'Mobilidade funcional', motor, Decimal('120.00')),
        ]
        appointments = []
        for index, (name, age, district, condition, appointment_type, value) in enumerate(patients, start=1):
            patient, _ = Paciente.objects.update_or_create(
                fisioterapeuta=therapist,
                nome=name,
                defaults={
                    'empresa': company,
                    'idade': age,
                    'telefone': f'(11) 98888-{index:04d}',
                    'email': f'paciente{index}@demo.invalid',
                    'endereco': f'Rua Exemplo, {index * 100} - {district}, Sao Paulo',
                    'quadro_clinico': condition,
                    'frequencia_por_dia': 1,
                },
            )
            appointment, _ = Atendimento.objects.update_or_create(
                fisioterapeuta=therapist,
                paciente=patient,
                tipo_atendimento=appointment_type,
                defaults={
                    'empresa': company,
                    'valor_por_sessao': value,
                    'observacoes': '[DEMO] Atendimento para apresentacao.',
                    'ativo': True,
                },
            )
            appointments.append(appointment)

        Sessao.objects.filter(
            atendimento__fisioterapeuta=therapist,
            observacoes__startswith='[DEMO]',
        ).delete()
        today = timezone.localdate()
        schedule = [
            (-75, 9, 0, True),
            (-45, 10, 30, True),
            (-14, 14, 0, False),
            (0, 9, 0, True),
            (0, 11, 0, True),
            (0, 14, 30, False),
            (1, 10, 0, False),
            (3, 15, 30, False),
            (7, 9, 30, False),
        ]
        demo_sessions = []
        for index, (day_offset, hour, minute, attended) in enumerate(schedule):
            appointment = appointments[index % len(appointments)]
            local_datetime = timezone.make_aware(
                datetime.combine(today + timedelta(days=day_offset), time(hour, minute)),
            )
            session = Sessao.objects.create(
                atendimento=appointment,
                data_hora=local_datetime,
                duracao_minutos=60,
                valor_sessao=appointment.valor_por_sessao,
                compareceu=attended,
                observacoes='[DEMO] Sessao gerada automaticamente.',
            )
            demo_sessions.append(session)

        travel_data = [
            ('12.40', '9.20'),
            ('18.00', '13.50'),
            ('8.60', '6.40'),
            ('15.20', '11.30'),
            ('6.80', '5.10'),
            ('21.50', '16.10'),
            ('10.00', '7.50'),
            ('14.70', '11.00'),
            ('9.30', '7.00'),
        ]
        for session, (distance, cost) in zip(demo_sessions, travel_data):
            Deslocamento.objects.create(
                sessao=session,
                distancia_km=Decimal(distance),
                custo=Decimal(cost),
            )

        denial_data = [
            (demo_sessions[0], 'Saude em Casa Demo', '35.00', 'Documento incompleto', 'confirmada'),
            (demo_sessions[1], 'Saude em Casa Demo', '50.00', 'Divergencia de codigo', 'pendente'),
            (demo_sessions[2], 'Convenio Exemplo', '40.00', 'Prazo de envio', 'revertida'),
        ]
        for session, operator, value, reason, status in denial_data:
            Glosa.objects.create(
                sessao=session,
                operadora=operator,
                valor=Decimal(value),
                motivo=reason,
                status=status,
            )

        self.stdout.write(self.style.SUCCESS('Usuario e massa de demonstracao atualizados.'))