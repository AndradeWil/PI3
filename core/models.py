from django.contrib.auth.models import User
from django.db import models


class Fisioterapeuta(models.Model):
	user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='fisioterapeuta')
	crefito = models.CharField(max_length=20, blank=True)
	telefone = models.CharField(max_length=20, blank=True)
	cpf = models.CharField(max_length=14, blank=True)

	def __str__(self):
		return self.user.get_full_name() or self.user.username


class TipoAtendimento(models.Model):
	fisioterapeuta = models.ForeignKey(Fisioterapeuta, on_delete=models.CASCADE, related_name='tipos_atendimento')
	nome = models.CharField(max_length=100)
	descricao = models.TextField(blank=True)
	valor_padrao = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

	class Meta:
		unique_together = ('fisioterapeuta', 'nome')

	def __str__(self):
		return self.nome


class Empresa(models.Model):
	fisioterapeuta = models.ForeignKey(Fisioterapeuta, on_delete=models.CASCADE, related_name='empresas')
	nome = models.CharField(max_length=150)
	contato = models.CharField(max_length=120, blank=True)
	telefone = models.CharField(max_length=20, blank=True)
	email = models.EmailField(blank=True)

	class Meta:
		unique_together = ('fisioterapeuta', 'nome')

	def __str__(self):
		return self.nome


class Paciente(models.Model):
	fisioterapeuta = models.ForeignKey(Fisioterapeuta, on_delete=models.CASCADE, related_name='pacientes')
	empresa = models.ForeignKey(Empresa, on_delete=models.SET_NULL, null=True, blank=True, related_name='pacientes')
	nome = models.CharField(max_length=150)
	idade = models.PositiveIntegerField(null=True, blank=True)
	telefone = models.CharField(max_length=20, blank=True)
	email = models.EmailField(blank=True)
	endereco = models.CharField(max_length=255, blank=True)
	quadro_clinico = models.TextField()
	frequencia_por_dia = models.PositiveIntegerField(default=1)

	def __str__(self):
		return self.nome


class Atendimento(models.Model):
	fisioterapeuta = models.ForeignKey(Fisioterapeuta, on_delete=models.CASCADE, related_name='atendimentos')
	paciente = models.ForeignKey(Paciente, on_delete=models.CASCADE, related_name='atendimentos')
	empresa = models.ForeignKey(Empresa, on_delete=models.SET_NULL, null=True, blank=True, related_name='atendimentos')
	tipo_atendimento = models.ForeignKey(TipoAtendimento, on_delete=models.PROTECT, related_name='atendimentos')
	valor_por_sessao = models.DecimalField(max_digits=10, decimal_places=2)
	observacoes = models.TextField(blank=True)
	ativo = models.BooleanField(default=True)
	criado_em = models.DateTimeField(auto_now_add=True)

	def __str__(self):
		return f'{self.paciente.nome} - {self.tipo_atendimento.nome}'


class Sessao(models.Model):
	atendimento = models.ForeignKey(Atendimento, on_delete=models.CASCADE, related_name='sessoes')
	data_hora = models.DateTimeField()
	duracao_minutos = models.PositiveIntegerField()
	valor_sessao = models.DecimalField(max_digits=10, decimal_places=2)
	compareceu = models.BooleanField(default=True)
	observacoes = models.TextField(blank=True)
	criado_em = models.DateTimeField(auto_now_add=True)

	class Meta:
		ordering = ['-data_hora']

	def __str__(self):
		return f'{self.atendimento.paciente.nome} em {self.data_hora:%d/%m/%Y %H:%M}'
