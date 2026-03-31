from decimal import Decimal

from django.contrib.auth.models import User
from django.db import IntegrityError
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone

from .forms import AtendimentoForm, PacienteForm, SessaoForm
from .models import Atendimento, Empresa, Fisioterapeuta, Paciente, Sessao, TipoAtendimento


class BaseDataMixin:
	def setUp(self):
		self.user = User.objects.create_user(username='fisio1', password='senha-forte-123')
		self.fisio = Fisioterapeuta.objects.create(user=self.user, crefito='1111', telefone='1199999', cpf='12345678900')

		self.user2 = User.objects.create_user(username='fisio2', password='senha-forte-456')
		self.fisio2 = Fisioterapeuta.objects.create(user=self.user2, crefito='2222', telefone='1188888', cpf='98765432100')

		self.empresa = Empresa.objects.create(fisioterapeuta=self.fisio, nome='Empresa A')
		self.empresa_outro = Empresa.objects.create(fisioterapeuta=self.fisio2, nome='Empresa B')

		self.tipo = TipoAtendimento.objects.create(fisioterapeuta=self.fisio, nome='RPG', valor_padrao=Decimal('120.00'))
		self.tipo_outro = TipoAtendimento.objects.create(fisioterapeuta=self.fisio2, nome='Pilates', valor_padrao=Decimal('90.00'))

		self.paciente = Paciente.objects.create(
			fisioterapeuta=self.fisio,
			empresa=self.empresa,
			nome='Paciente Um',
			idade=35,
			telefone='11911111111',
			email='paciente1@email.com',
			endereco='Rua A',
			quadro_clinico='Dor lombar',
			frequencia_por_dia=1,
		)
		self.paciente_outro = Paciente.objects.create(
			fisioterapeuta=self.fisio2,
			empresa=self.empresa_outro,
			nome='Paciente Dois',
			idade=28,
			telefone='11922222222',
			email='paciente2@email.com',
			endereco='Rua B',
			quadro_clinico='Reabilitacao',
			frequencia_por_dia=2,
		)

		self.atendimento = Atendimento.objects.create(
			fisioterapeuta=self.fisio,
			paciente=self.paciente,
			empresa=self.empresa,
			tipo_atendimento=self.tipo,
			valor_por_sessao=Decimal('120.00'),
			observacoes='Plano inicial',
			ativo=True,
		)
		self.atendimento_outro = Atendimento.objects.create(
			fisioterapeuta=self.fisio2,
			paciente=self.paciente_outro,
			empresa=self.empresa_outro,
			tipo_atendimento=self.tipo_outro,
			valor_por_sessao=Decimal('90.00'),
			observacoes='Plano outro usuario',
			ativo=True,
		)

		self.sessao = Sessao.objects.create(
			atendimento=self.atendimento,
			data_hora=timezone.now(),
			duracao_minutos=60,
			valor_sessao=Decimal('120.00'),
			compareceu=True,
			observacoes='Sem intercorrencias',
		)


class ModelTests(BaseDataMixin, TestCase):
	def test_str_models(self):
		self.assertIn('fisio1', str(self.fisio))
		self.assertEqual(str(self.tipo), 'RPG')
		self.assertEqual(str(self.empresa), 'Empresa A')
		self.assertEqual(str(self.paciente), 'Paciente Um')
		self.assertIn('Paciente Um', str(self.atendimento))

	def test_unique_together_tipo_atendimento_por_fisioterapeuta(self):
		with self.assertRaises(IntegrityError):
			TipoAtendimento.objects.create(fisioterapeuta=self.fisio, nome='RPG')

	def test_unique_together_empresa_por_fisioterapeuta(self):
		with self.assertRaises(IntegrityError):
			Empresa.objects.create(fisioterapeuta=self.fisio, nome='Empresa A')

	def test_delete_atendimento_apaga_sessoes_cascade(self):
		atendimento_id = self.atendimento.id
		self.atendimento.delete()
		self.assertFalse(Sessao.objects.filter(atendimento_id=atendimento_id).exists())


class FormTests(BaseDataMixin, TestCase):
	def test_paciente_form_filtra_empresas_por_fisioterapeuta(self):
		form = PacienteForm(fisioterapeuta=self.fisio)
		empresas_ids = list(form.fields['empresa'].queryset.values_list('id', flat=True))
		self.assertIn(self.empresa.id, empresas_ids)
		self.assertNotIn(self.empresa_outro.id, empresas_ids)

	def test_atendimento_form_filtra_relacoes_por_fisioterapeuta(self):
		form = AtendimentoForm(fisioterapeuta=self.fisio)
		pacientes_ids = list(form.fields['paciente'].queryset.values_list('id', flat=True))
		empresas_ids = list(form.fields['empresa'].queryset.values_list('id', flat=True))
		tipos_ids = list(form.fields['tipo_atendimento'].queryset.values_list('id', flat=True))

		self.assertIn(self.paciente.id, pacientes_ids)
		self.assertNotIn(self.paciente_outro.id, pacientes_ids)
		self.assertIn(self.empresa.id, empresas_ids)
		self.assertNotIn(self.empresa_outro.id, empresas_ids)
		self.assertIn(self.tipo.id, tipos_ids)
		self.assertNotIn(self.tipo_outro.id, tipos_ids)

	def test_sessao_form_lista_somente_atendimentos_ativos_do_usuario(self):
		self.atendimento_outro.ativo = False
		self.atendimento_outro.save()

		form = SessaoForm(fisioterapeuta=self.fisio)
		atendimento_ids = list(form.fields['atendimento'].queryset.values_list('id', flat=True))

		self.assertIn(self.atendimento.id, atendimento_ids)
		self.assertNotIn(self.atendimento_outro.id, atendimento_ids)


class ViewTests(BaseDataMixin, TestCase):
	def setUp(self):
		super().setUp()
		self.client.login(username='fisio1', password='senha-forte-123')

	def test_rotas_exigem_login(self):
		self.client.logout()
		rotas = [
			reverse('dashboard'),
			reverse('tipos_atendimento'),
			reverse('empresas'),
			reverse('pacientes'),
			reverse('atendimentos'),
			reverse('sessoes'),
			reverse('relatorio'),
			reverse('painel_financeiro'),
		]
		for rota in rotas:
			response = self.client.get(rota)
			self.assertEqual(response.status_code, 302)
			self.assertIn('/accounts/login/', response.url)

	def test_registro_cria_usuario_e_fisioterapeuta(self):
		self.client.logout()
		response = self.client.post(
			reverse('registro'),
			{
				'username': 'novo_usuario',
				'password1': 'SenhaForte!12345',
				'password2': 'SenhaForte!12345',
				'nome': 'Novo Fisio',
				'email': 'novo@email.com',
				'crefito': '3333',
				'telefone': '11777777777',
				'cpf': '11122233344',
			},
			follow=True,
		)
		self.assertEqual(response.status_code, 200)
		self.assertTrue(User.objects.filter(username='novo_usuario').exists())
		self.assertTrue(Fisioterapeuta.objects.filter(user__username='novo_usuario').exists())

	def test_dashboard_retorna_totais_usuario_logado(self):
		response = self.client.get(reverse('dashboard'))
		self.assertEqual(response.status_code, 200)
		self.assertEqual(response.context['total_pacientes'], 1)
		self.assertEqual(response.context['total_atendimentos'], 1)
		self.assertEqual(response.context['total_sessoes'], 1)

	def test_criar_tipo_atendimento(self):
		response = self.client.post(
			reverse('tipos_atendimento'),
			{'nome': 'Alongamento', 'descricao': 'Descricao', 'valor_padrao': '80.00'},
		)
		self.assertEqual(response.status_code, 302)
		self.assertTrue(TipoAtendimento.objects.filter(fisioterapeuta=self.fisio, nome='Alongamento').exists())

	def test_excluir_tipo_atendimento_protegido_em_uso(self):
		response = self.client.post(reverse('excluir_tipo_atendimento', args=[self.tipo.id]))
		self.assertEqual(response.status_code, 200)
		self.assertTrue(TipoAtendimento.objects.filter(id=self.tipo.id).exists())

	def test_criar_empresa(self):
		response = self.client.post(
			reverse('empresas'),
			{'nome': 'Empresa Nova', 'contato': 'RH', 'telefone': '11933333333', 'email': 'rh@empresa.com'},
		)
		self.assertEqual(response.status_code, 302)
		self.assertTrue(Empresa.objects.filter(fisioterapeuta=self.fisio, nome='Empresa Nova').exists())

	def test_criar_paciente(self):
		response = self.client.post(
			reverse('pacientes'),
			{
				'nome': 'Paciente Tres',
				'idade': 40,
				'telefone': '11944444444',
				'email': 'paciente3@email.com',
				'endereco': 'Rua C',
				'quadro_clinico': 'Cervicalgia',
				'frequencia_por_dia': 1,
				'empresa': self.empresa.id,
			},
		)
		self.assertEqual(response.status_code, 302)
		self.assertTrue(Paciente.objects.filter(fisioterapeuta=self.fisio, nome='Paciente Tres').exists())

	def test_criar_atendimento(self):
		novo_paciente = Paciente.objects.create(
			fisioterapeuta=self.fisio,
			empresa=self.empresa,
			nome='Paciente Quatro',
			idade=31,
			quadro_clinico='Pos operatorio',
			frequencia_por_dia=1,
		)
		response = self.client.post(
			reverse('atendimentos'),
			{
				'paciente': novo_paciente.id,
				'empresa': self.empresa.id,
				'tipo_atendimento': self.tipo.id,
				'valor_por_sessao': '130.00',
				'observacoes': 'Novo plano',
				'ativo': True,
			},
		)
		self.assertEqual(response.status_code, 302)
		self.assertTrue(Atendimento.objects.filter(fisioterapeuta=self.fisio, paciente=novo_paciente).exists())

	def test_criar_sessao(self):
		response = self.client.post(
			reverse('sessoes'),
			{
				'atendimento': self.atendimento.id,
				'data_hora': timezone.now().strftime('%Y-%m-%dT%H:%M'),
				'duracao_minutos': 50,
				'valor_sessao': '120.00',
				'compareceu': True,
				'observacoes': 'Evolucao boa',
			},
		)
		self.assertEqual(response.status_code, 302)
		self.assertEqual(Sessao.objects.filter(atendimento=self.atendimento).count(), 2)

	def test_bater_ponto_cria_sessao_rapida(self):
		count_antes = Sessao.objects.filter(atendimento=self.atendimento).count()
		response = self.client.post(reverse('bater_ponto', args=[self.atendimento.id]))
		self.assertEqual(response.status_code, 302)
		count_depois = Sessao.objects.filter(atendimento=self.atendimento).count()
		self.assertEqual(count_depois, count_antes + 1)

	def test_relatorio_lista_somente_dados_do_usuario_logado(self):
		Sessao.objects.create(
			atendimento=self.atendimento_outro,
			data_hora=timezone.now(),
			duracao_minutos=45,
			valor_sessao=Decimal('90.00'),
			compareceu=True,
			observacoes='Nao deve aparecer',
		)

		response = self.client.get(reverse('relatorio'))
		self.assertEqual(response.status_code, 200)
		self.assertEqual(response.context['total_sessoes'], 1)

	def test_exportar_relatorio_pdf(self):
		hoje = timezone.now().date().isoformat()
		response = self.client.get(reverse('exportar_relatorio_pdf'), {'data_inicio': hoje, 'data_fim': hoje})
		self.assertEqual(response.status_code, 200)
		self.assertEqual(response['Content-Type'], 'application/pdf')
		self.assertIn('relatorio_atendimentos.pdf', response['Content-Disposition'])

	def test_painel_financeiro_calcula_total_geral_usuario(self):
		Sessao.objects.create(
			atendimento=self.atendimento,
			data_hora=timezone.now(),
			duracao_minutos=30,
			valor_sessao=Decimal('80.00'),
			compareceu=True,
			observacoes='Sessao extra',
		)
		response = self.client.get(reverse('painel_financeiro'))
		self.assertEqual(response.status_code, 200)
		self.assertEqual(response.context['total_geral'], Decimal('200.00'))
