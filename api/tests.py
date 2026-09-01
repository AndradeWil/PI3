from datetime import timedelta
from decimal import Decimal

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