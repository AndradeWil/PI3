from datetime import timedelta
from decimal import Decimal

from django.contrib.auth.models import User
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from core.models import Atendimento, Fisioterapeuta, Paciente, Sessao, TipoAtendimento


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