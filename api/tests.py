from datetime import timedelta
from decimal import Decimal
from uuid import uuid4

from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Atendimento, Empresa, Fisioterapeuta, Paciente, Sessao, TipoAtendimento


class DashboardApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='ana', password='senha-forte-123')
        self.fisioterapeuta = Fisioterapeuta.objects.create(user=self.user, crefito='12345')
        self.other_user = User.objects.create_user(username='bia', password='senha-forte-456')
        self.other_fisioterapeuta = Fisioterapeuta.objects.create(user=self.other_user)

        self._create_session(self.fisioterapeuta, 'Maria', Decimal('120.00'))
        self._create_session(self.other_fisioterapeuta, 'Paciente de Bia', Decimal('999.00'))

    def _create_session(self, fisioterapeuta, patient_name, value):
        paciente = Paciente.objects.create(
            fisioterapeuta=fisioterapeuta,
            nome=patient_name,
            endereco='Rua de teste',
            quadro_clinico='Teste',
        )
        tipo = TipoAtendimento.objects.create(
            fisioterapeuta=fisioterapeuta,
            nome=f'Tipo {patient_name}',
        )
        atendimento = Atendimento.objects.create(
            fisioterapeuta=fisioterapeuta,
            paciente=paciente,
            tipo_atendimento=tipo,
            valor_por_sessao=value,
        )
        return Sessao.objects.create(
            atendimento=atendimento,
            data_hora=timezone.now() + timedelta(hours=1),
            duracao_minutos=60,
            valor_sessao=value,
        )

    def test_dashboard_requires_authentication(self):
        response = self.client.get(reverse('api_dashboard'))

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_token_authenticates_and_dashboard_is_isolated(self):
        token_response = self.client.post(reverse('api_token'), {
            'username': 'ana',
            'password': 'senha-forte-123',
        })
        self.assertEqual(token_response.status_code, status.HTTP_200_OK)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token_response.data['access']}")

        response = self.client.get(reverse('api_dashboard'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['monthly_revenue'], '120')
        self.assertEqual(response.data['active_patients'], 1)
        self.assertEqual(response.data['today_sessions'], 1)
        self.assertEqual(len(response.data['today_agenda']), 1)
        self.assertEqual(response.data['today_agenda'][0]['patient_name'], 'Maria')

    def test_me_returns_authenticated_profile(self):
        self.client.force_authenticate(self.user)

        response = self.client.get(reverse('api_me'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['username'], 'ana')
        self.assertEqual(response.data['crefito'], '12345')

    def test_refresh_rotates_token_and_logout_blacklists_it(self):
        token_response = self.client.post(reverse('api_token'), {
            'username': 'ana',
            'password': 'senha-forte-123',
        })
        access = token_response.data['access']
        refresh = token_response.data['refresh']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')

        logout_response = self.client.post(reverse('api_logout'), {'refresh': refresh})
        refresh_response = self.client.post(reverse('api_token_refresh'), {'refresh': refresh})

        self.assertEqual(logout_response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertEqual(refresh_response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_user_without_therapist_profile_receives_not_found(self):
        user = User.objects.create_user(username='sem-perfil', password='senha-123')
        self.client.force_authenticate(user)

        response = self.client.get(reverse('api_me'))

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class PacienteApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='ana-pacientes', password='senha-123')
        self.fisioterapeuta = Fisioterapeuta.objects.create(user=self.user)
        self.other_user = User.objects.create_user(username='bia-pacientes', password='senha-456')
        self.other_fisioterapeuta = Fisioterapeuta.objects.create(user=self.other_user)
        self.maria = Paciente.objects.create(
            fisioterapeuta=self.fisioterapeuta,
            nome='Maria Silva',
            telefone='11999990000',
            email='maria@example.com',
            endereco='Rua A, 10',
            quadro_clinico='Pos-operatorio de joelho',
            frequencia_por_dia=1,
        )
        Paciente.objects.create(
            fisioterapeuta=self.fisioterapeuta,
            nome='Joao Souza',
            quadro_clinico='Reabilitacao motora',
        )
        self.other_patient = Paciente.objects.create(
            fisioterapeuta=self.other_fisioterapeuta,
            nome='Paciente de Bia',
            quadro_clinico='Nao pode aparecer',
        )

    def test_list_requires_authentication(self):
        response = self.client.get(reverse('api_pacientes'))

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_list_is_paginated_searchable_and_isolated(self):
        self.client.force_authenticate(self.user)

        response = self.client.get(reverse('api_pacientes'), {'search': 'Maria'})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['nome'], 'Maria Silva')
        self.assertNotContains(response, 'Paciente de Bia')

    def test_detail_returns_patient_owned_by_authenticated_therapist(self):
        self.client.force_authenticate(self.user)

        response = self.client.get(reverse('api_paciente_detail', args=[self.maria.id]))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['quadro_clinico'], 'Pos-operatorio de joelho')

    def test_detail_hides_patient_owned_by_another_therapist(self):
        self.client.force_authenticate(self.user)

        response = self.client.get(reverse('api_paciente_detail', args=[self.other_patient.id]))

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_create_assigns_authenticated_therapist(self):
        self.client.force_authenticate(self.user)

        response = self.client.post(reverse('api_pacientes'), {
            'nome': 'Novo Paciente',
            'quadro_clinico': 'Avaliacao inicial',
            'frequencia_por_dia': 1,
        })

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        paciente = Paciente.objects.get(id=response.data['id'])
        self.assertEqual(paciente.fisioterapeuta, self.fisioterapeuta)

    def test_update_changes_only_owned_patient(self):
        self.client.force_authenticate(self.user)

        response = self.client.patch(
            reverse('api_paciente_detail', args=[self.maria.id]),
            {'telefone': '11888887777'},
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.maria.refresh_from_db()
        self.assertEqual(self.maria.telefone, '11888887777')

    def test_create_rejects_company_owned_by_another_therapist(self):
        self.client.force_authenticate(self.user)
        other_company = Empresa.objects.create(
            fisioterapeuta=self.other_fisioterapeuta,
            nome='Empresa de Bia',
        )

        response = self.client.post(reverse('api_pacientes'), {
            'nome': 'Paciente invalido',
            'quadro_clinico': 'Teste',
            'frequencia_por_dia': 1,
            'empresa': other_company.id,
        })

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(Paciente.objects.filter(nome='Paciente invalido').exists())


class SessaoApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='agenda-ana', password='senha-123')
        self.fisioterapeuta = Fisioterapeuta.objects.create(user=self.user)
        self.other_user = User.objects.create_user(username='agenda-bia', password='senha-456')
        self.other_fisioterapeuta = Fisioterapeuta.objects.create(user=self.other_user)
        self.selected_date = timezone.localdate() + timedelta(days=2)
        self.appointment = self._create_session(self.fisioterapeuta, 'Maria', self.selected_date, 14).atendimento
        self._create_session(self.fisioterapeuta, 'Joao', self.selected_date + timedelta(days=1), 10)
        self.other_appointment = self._create_session(
            self.other_fisioterapeuta,
            'Paciente de Bia',
            self.selected_date,
            16,
        ).atendimento

    def _create_session(self, fisioterapeuta, patient_name, selected_date, hour):
        patient = Paciente.objects.create(
            fisioterapeuta=fisioterapeuta,
            nome=patient_name,
            endereco='Rua da agenda',
            quadro_clinico='Teste',
        )
        appointment_type = TipoAtendimento.objects.create(
            fisioterapeuta=fisioterapeuta,
            nome=f'Tipo {patient_name}',
        )
        appointment = Atendimento.objects.create(
            fisioterapeuta=fisioterapeuta,
            paciente=patient,
            tipo_atendimento=appointment_type,
            valor_por_sessao=Decimal('100.00'),
        )
        session_time = timezone.make_aware(
            timezone.datetime.combine(selected_date, timezone.datetime.min.time()).replace(hour=hour),
        )
        return Sessao.objects.create(
            atendimento=appointment,
            data_hora=session_time,
            duracao_minutos=60,
            valor_sessao=Decimal('100.00'),
        )

    def test_list_requires_authentication(self):
        response = self.client.get(reverse('api_sessoes'))

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_list_filters_date_and_authenticated_therapist(self):
        self.client.force_authenticate(self.user)

        response = self.client.get(reverse('api_sessoes'), {'data': self.selected_date.isoformat()})

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['count'], 1)
        self.assertEqual(response.data['results'][0]['paciente_nome'], 'Maria')
        self.assertEqual(response.data['results'][0]['endereco'], 'Rua da agenda')

    def test_list_rejects_invalid_date(self):
        self.client.force_authenticate(self.user)

        response = self.client.get(reverse('api_sessoes'), {'data': '01-09-2026'})

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_active_appointments_are_isolated(self):
        self.client.force_authenticate(self.user)

        response = self.client.get(reverse('api_atendimentos_ativos'))

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        patient_names = [item['paciente_nome'] for item in response.data]
        self.assertCountEqual(patient_names, ['Joao', 'Maria'])

    def test_quick_clock_in_is_idempotent(self):
        self.client.force_authenticate(self.user)
        key = str(uuid4())
        url = reverse('api_bater_ponto', args=[self.appointment.id])

        first = self.client.post(url, HTTP_IDEMPOTENCY_KEY=key)
        second = self.client.post(url, HTTP_IDEMPOTENCY_KEY=key)

        self.assertEqual(first.status_code, status.HTTP_201_CREATED)
        self.assertEqual(second.status_code, status.HTTP_200_OK)
        self.assertEqual(first.data['id'], second.data['id'])
        self.assertEqual(Sessao.objects.filter(idempotency_key=key).count(), 1)

    def test_quick_clock_in_hides_another_therapists_appointment(self):
        self.client.force_authenticate(self.user)

        response = self.client.post(
            reverse('api_bater_ponto', args=[self.other_appointment.id]),
            HTTP_IDEMPOTENCY_KEY=str(uuid4()),
        )

        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)


class AtendimentoApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='atendimento-ana', password='senha-123')
        self.therapist = Fisioterapeuta.objects.create(user=self.user)
        self.other_user = User.objects.create_user(username='atendimento-bia', password='senha-456')
        self.other_therapist = Fisioterapeuta.objects.create(user=self.other_user)
        self.patient = Paciente.objects.create(
            fisioterapeuta=self.therapist,
            nome='Maria Silva',
            quadro_clinico='Teste',
        )
        self.other_patient = Paciente.objects.create(
            fisioterapeuta=self.other_therapist,
            nome='Paciente de Bia',
            quadro_clinico='Teste',
        )
        self.company = Empresa.objects.create(fisioterapeuta=self.therapist, nome='Empresa Vida')
        self.appointment_type = TipoAtendimento.objects.create(
            fisioterapeuta=self.therapist,
            nome='Fisioterapia Motora',
            valor_padrao=Decimal('120.00'),
        )
        self.appointment = Atendimento.objects.create(
            fisioterapeuta=self.therapist,
            paciente=self.patient,
            empresa=self.company,
            tipo_atendimento=self.appointment_type,
            valor_por_sessao=Decimal('120.00'),
        )
        Atendimento.objects.create(
            fisioterapeuta=self.other_therapist,
            paciente=self.other_patient,
            tipo_atendimento=TipoAtendimento.objects.create(
                fisioterapeuta=self.other_therapist,
                nome='Tipo de Bia',
            ),
            valor_por_sessao=Decimal('999.00'),
        )

    def test_list_and_options_are_isolated(self):
        self.client.force_authenticate(self.user)

        list_response = self.client.get(reverse('api_atendimentos'))
        options_response = self.client.get(reverse('api_atendimentos_opcoes'))

        self.assertEqual(list_response.status_code, status.HTTP_200_OK)
        self.assertEqual(list_response.data['count'], 1)
        self.assertEqual(list_response.data['results'][0]['paciente_nome'], 'Maria Silva')
        self.assertEqual(options_response.status_code, status.HTTP_200_OK)
        self.assertEqual(options_response.data['pacientes'], [{'id': self.patient.id, 'nome': 'Maria Silva'}])

    def test_create_assigns_authenticated_therapist(self):
        self.client.force_authenticate(self.user)

        response = self.client.post(reverse('api_atendimentos'), {
            'paciente': self.patient.id,
            'empresa': self.company.id,
            'tipo_atendimento': self.appointment_type.id,
            'valor_por_sessao': '135.00',
            'observacoes': 'Novo plano',
            'ativo': True,
        })

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        created = Atendimento.objects.get(id=response.data['id'])
        self.assertEqual(created.fisioterapeuta, self.therapist)

    def test_create_rejects_patient_from_another_therapist(self):
        self.client.force_authenticate(self.user)

        response = self.client.post(reverse('api_atendimentos'), {
            'paciente': self.other_patient.id,
            'tipo_atendimento': self.appointment_type.id,
            'valor_por_sessao': '120.00',
            'ativo': True,
        })

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_update_and_cross_tenant_detail(self):
        self.client.force_authenticate(self.user)
        update_response = self.client.patch(
            reverse('api_atendimento_detail', args=[self.appointment.id]),
            {'ativo': False},
        )
        other_appointment = Atendimento.objects.filter(fisioterapeuta=self.other_therapist).get()
        cross_response = self.client.get(
            reverse('api_atendimento_detail', args=[other_appointment.id]),
        )

        self.assertEqual(update_response.status_code, status.HTTP_200_OK)
        self.assertFalse(update_response.data['ativo'])
        self.assertEqual(cross_response.status_code, status.HTTP_404_NOT_FOUND)


class CadastrosAuxiliaresApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='cadastros-ana', password='senha-123')
        self.therapist = Fisioterapeuta.objects.create(user=self.user)
        self.other_user = User.objects.create_user(username='cadastros-bia', password='senha-456')
        self.other_therapist = Fisioterapeuta.objects.create(user=self.other_user)
        self.company = Empresa.objects.create(fisioterapeuta=self.therapist, nome='Empresa Vida')
        Empresa.objects.create(fisioterapeuta=self.other_therapist, nome='Empresa de Bia')
        self.appointment_type = TipoAtendimento.objects.create(
            fisioterapeuta=self.therapist,
            nome='Fisioterapia Motora',
            valor_padrao=Decimal('120.00'),
        )
        TipoAtendimento.objects.create(
            fisioterapeuta=self.other_therapist,
            nome='Tipo de Bia',
        )
        self.client.force_authenticate(self.user)

    def test_lists_are_isolated_and_create_assigns_owner(self):
        companies = self.client.get(reverse('api_empresas'))
        types = self.client.get(reverse('api_tipos_atendimento'))
        created = self.client.post(reverse('api_empresas'), {'nome': 'Nova Empresa'})

        self.assertEqual(companies.data['count'], 1)
        self.assertEqual(companies.data['results'][0]['nome'], 'Empresa Vida')
        self.assertEqual(types.data['count'], 1)
        self.assertEqual(types.data['results'][0]['nome'], 'Fisioterapia Motora')
        self.assertEqual(created.status_code, status.HTTP_201_CREATED)
        self.assertEqual(
            Empresa.objects.get(id=created.data['id']).fisioterapeuta,
            self.therapist,
        )

    def test_duplicate_names_are_rejected_case_insensitively(self):
        company = self.client.post(reverse('api_empresas'), {'nome': 'empresa vida'})
        appointment_type = self.client.post(
            reverse('api_tipos_atendimento'),
            {'nome': 'FISIOTERAPIA MOTORA'},
        )

        self.assertEqual(company.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(appointment_type.status_code, status.HTTP_400_BAD_REQUEST)

    def test_deleting_company_preserves_patient_as_private(self):
        patient = Paciente.objects.create(
            fisioterapeuta=self.therapist,
            empresa=self.company,
            nome='Maria',
            quadro_clinico='Teste',
        )

        response = self.client.delete(reverse('api_empresa_detail', args=[self.company.id]))

        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        patient.refresh_from_db()
        self.assertIsNone(patient.empresa)

    def test_deleting_type_in_use_returns_conflict(self):
        patient = Paciente.objects.create(
            fisioterapeuta=self.therapist,
            nome='Maria',
            quadro_clinico='Teste',
        )
        Atendimento.objects.create(
            fisioterapeuta=self.therapist,
            paciente=patient,
            tipo_atendimento=self.appointment_type,
            valor_por_sessao=Decimal('120.00'),
        )

        response = self.client.delete(
            reverse('api_tipo_atendimento_detail', args=[self.appointment_type.id]),
        )

        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)
        self.assertEqual(response.data['code'], 'protected_resource')