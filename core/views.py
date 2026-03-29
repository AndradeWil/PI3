from decimal import Decimal

from django.contrib.auth import login
from django.contrib.auth.decorators import login_required
from django.contrib.auth.forms import UserCreationForm
from django.db.models import ProtectedError
from django.db.models import Sum
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.utils import timezone
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas

from .forms import (
	AtendimentoForm,
	EmpresaForm,
	FisioterapeutaCadastroForm,
	PacienteForm,
	RelatorioPeriodoForm,
	SessaoForm,
	TipoAtendimentoForm,
)
from .models import Atendimento, Fisioterapeuta, Sessao


def registro(request):
	if request.user.is_authenticated:
		return redirect('dashboard')

	user_form = UserCreationForm(request.POST or None)
	perfil_form = FisioterapeutaCadastroForm(request.POST or None)

	if request.method == 'POST' and user_form.is_valid() and perfil_form.is_valid():
		user = user_form.save(commit=False)
		user.email = perfil_form.cleaned_data['email']
		user.first_name = perfil_form.cleaned_data['nome']
		user.save()

		Fisioterapeuta.objects.create(
			user=user,
			crefito=perfil_form.cleaned_data['crefito'],
			telefone=perfil_form.cleaned_data['telefone'],
			cpf=perfil_form.cleaned_data['cpf'],
		)

		login(request, user)
		return redirect('dashboard')

	return render(request, 'core/registro.html', {'user_form': user_form, 'perfil_form': perfil_form})


def _fisioterapeuta_do_usuario(user):
	return get_object_or_404(Fisioterapeuta, user=user)


def _filtro_periodo(request, queryset):
	form = RelatorioPeriodoForm(request.GET or None)
	if form.is_valid():
		data_inicio = form.cleaned_data.get('data_inicio')
		data_fim = form.cleaned_data.get('data_fim')
		if data_inicio:
			queryset = queryset.filter(data_hora__date__gte=data_inicio)
		if data_fim:
			queryset = queryset.filter(data_hora__date__lte=data_fim)
		return form, queryset, data_inicio, data_fim
	return form, queryset, None, None


@login_required
def dashboard(request):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	atendimentos = Atendimento.objects.filter(fisioterapeuta=fisioterapeuta)
	sessoes = Sessao.objects.filter(atendimento__fisioterapeuta=fisioterapeuta)

	total_mes = (
		sessoes.filter(data_hora__month=timezone.now().month, data_hora__year=timezone.now().year)
		.aggregate(total=Sum('valor_sessao'))
		.get('total')
		or 0
	)

	contexto = {
		'total_pacientes': atendimentos.values('paciente').distinct().count(),
		'total_atendimentos': atendimentos.count(),
		'total_sessoes': sessoes.count(),
		'total_mes': total_mes,
		'ultimas_sessoes': sessoes.select_related('atendimento', 'atendimento__paciente')[:8],
	}
	return render(request, 'core/dashboard.html', contexto)


@login_required
def listar_criar_tipo_atendimento(request):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	form = TipoAtendimentoForm(request.POST or None)

	if request.method == 'POST' and form.is_valid():
		tipo = form.save(commit=False)
		tipo.fisioterapeuta = fisioterapeuta
		tipo.save()
		return redirect('tipos_atendimento')

	itens = fisioterapeuta.tipos_atendimento.all().order_by('nome')
	contexto = {
		'form': form,
		'itens': itens,
	}
	return render(request, 'core/tipos_atendimento.html', contexto)


@login_required
def editar_tipo_atendimento(request, tipo_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	tipo = get_object_or_404(fisioterapeuta.tipos_atendimento, id=tipo_id)
	form = TipoAtendimentoForm(request.POST or None, instance=tipo)
	if request.method == 'POST' and form.is_valid():
		form.save()
		return redirect('tipos_atendimento')
	return render(request, 'core/editar_item.html', {'form': form, 'titulo': f'Editar tipo de atendimento: {tipo.nome}'})


@login_required
def excluir_tipo_atendimento(request, tipo_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	tipo = get_object_or_404(fisioterapeuta.tipos_atendimento, id=tipo_id)
	if request.method == 'POST':
		try:
			tipo.delete()
			return redirect('tipos_atendimento')
		except ProtectedError:
			contexto = {
				'objeto': tipo,
				'voltar_url': 'tipos_atendimento',
				'erro': 'Este tipo de atendimento está vinculado a atendimentos e não pode ser excluído.',
			}
			return render(request, 'core/confirmar_exclusao.html', contexto)
	return render(request, 'core/confirmar_exclusao.html', {'objeto': tipo, 'voltar_url': 'tipos_atendimento'})


@login_required
def listar_criar_empresa(request):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	form = EmpresaForm(request.POST or None)

	if request.method == 'POST' and form.is_valid():
		empresa = form.save(commit=False)
		empresa.fisioterapeuta = fisioterapeuta
		empresa.save()
		return redirect('empresas')

	itens = fisioterapeuta.empresas.all().order_by('nome')
	contexto = {
		'form': form,
		'itens': itens,
	}
	return render(request, 'core/empresas.html', contexto)


@login_required
def editar_empresa(request, empresa_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	empresa = get_object_or_404(fisioterapeuta.empresas, id=empresa_id)
	form = EmpresaForm(request.POST or None, instance=empresa)
	if request.method == 'POST' and form.is_valid():
		form.save()
		return redirect('empresas')
	return render(request, 'core/editar_item.html', {'form': form, 'titulo': f'Editar empresa: {empresa.nome}'})


@login_required
def excluir_empresa(request, empresa_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	empresa = get_object_or_404(fisioterapeuta.empresas, id=empresa_id)
	if request.method == 'POST':
		empresa.delete()
		return redirect('empresas')
	return render(request, 'core/confirmar_exclusao.html', {'objeto': empresa, 'voltar_url': 'empresas'})


@login_required
def listar_criar_paciente(request):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	form = PacienteForm(request.POST or None, fisioterapeuta=fisioterapeuta)

	if request.method == 'POST' and form.is_valid():
		paciente = form.save(commit=False)
		paciente.fisioterapeuta = fisioterapeuta
		paciente.save()
		return redirect('pacientes')

	itens = fisioterapeuta.pacientes.all().order_by('nome')
	return render(request, 'core/pacientes.html', {'form': form, 'itens': itens, 'titulo': 'Pacientes'})


@login_required
def editar_paciente(request, paciente_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	paciente = get_object_or_404(fisioterapeuta.pacientes, id=paciente_id)
	form = PacienteForm(request.POST or None, instance=paciente, fisioterapeuta=fisioterapeuta)
	if request.method == 'POST' and form.is_valid():
		form.save()
		return redirect('pacientes')
	return render(request, 'core/editar_item.html', {'form': form, 'titulo': f'Editar paciente: {paciente.nome}'})


@login_required
def excluir_paciente(request, paciente_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	paciente = get_object_or_404(fisioterapeuta.pacientes, id=paciente_id)
	if request.method == 'POST':
		paciente.delete()
		return redirect('pacientes')
	return render(request, 'core/confirmar_exclusao.html', {'objeto': paciente, 'voltar_url': 'pacientes'})


@login_required
def listar_criar_atendimento(request):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	form = AtendimentoForm(request.POST or None, fisioterapeuta=fisioterapeuta)

	if request.method == 'POST' and form.is_valid():
		atendimento = form.save(commit=False)
		atendimento.fisioterapeuta = fisioterapeuta
		atendimento.save()
		return redirect('atendimentos')

	itens = fisioterapeuta.atendimentos.select_related('paciente', 'empresa', 'tipo_atendimento').all()
	return render(request, 'core/atendimentos.html', {'form': form, 'itens': itens, 'titulo': 'Atendimentos'})


@login_required
def editar_atendimento(request, atendimento_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	atendimento = get_object_or_404(fisioterapeuta.atendimentos, id=atendimento_id)
	form = AtendimentoForm(request.POST or None, instance=atendimento, fisioterapeuta=fisioterapeuta)
	if request.method == 'POST' and form.is_valid():
		form.save()
		return redirect('atendimentos')
	return render(request, 'core/editar_item.html', {'form': form, 'titulo': f'Editar atendimento: {atendimento}'})


@login_required
def excluir_atendimento(request, atendimento_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	atendimento = get_object_or_404(fisioterapeuta.atendimentos, id=atendimento_id)
	if request.method == 'POST':
		atendimento.delete()
		return redirect('atendimentos')
	return render(request, 'core/confirmar_exclusao.html', {'objeto': atendimento, 'voltar_url': 'atendimentos'})


@login_required
def listar_criar_sessao(request):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	form = SessaoForm(request.POST or None, fisioterapeuta=fisioterapeuta)

	if request.method == 'POST' and form.is_valid():
		form.save()
		return redirect('sessoes')

	itens = Sessao.objects.filter(atendimento__fisioterapeuta=fisioterapeuta).select_related('atendimento', 'atendimento__paciente')
	return render(request, 'core/sessoes.html', {'form': form, 'itens': itens, 'titulo': 'Sessões / Ponto'})


@login_required
def editar_sessao(request, sessao_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	sessao = get_object_or_404(Sessao, id=sessao_id, atendimento__fisioterapeuta=fisioterapeuta)
	form = SessaoForm(request.POST or None, instance=sessao, fisioterapeuta=fisioterapeuta)
	if request.method == 'POST' and form.is_valid():
		form.save()
		return redirect('sessoes')
	return render(request, 'core/editar_item.html', {'form': form, 'titulo': f'Editar sessão: {sessao}'})


@login_required
def excluir_sessao(request, sessao_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	sessao = get_object_or_404(Sessao, id=sessao_id, atendimento__fisioterapeuta=fisioterapeuta)
	if request.method == 'POST':
		sessao.delete()
		return redirect('sessoes')
	return render(request, 'core/confirmar_exclusao.html', {'objeto': sessao, 'voltar_url': 'sessoes'})


@login_required
def bater_ponto(request, atendimento_id):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	atendimento = get_object_or_404(Atendimento, id=atendimento_id, fisioterapeuta=fisioterapeuta)
	if request.method != 'POST':
		return redirect('atendimentos')
	Sessao.objects.create(
		atendimento=atendimento,
		data_hora=timezone.now(),
		duracao_minutos=60,
		valor_sessao=atendimento.valor_por_sessao,
		compareceu=True,
		observacoes='Registro rápido de ponto.',
	)
	return redirect('sessoes')


@login_required
def relatorio_atendimentos(request):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	sessoes = Sessao.objects.filter(atendimento__fisioterapeuta=fisioterapeuta).select_related(
		'atendimento',
		'atendimento__paciente',
		'atendimento__tipo_atendimento',
		'atendimento__empresa',
	)
	form, sessoes, data_inicio, data_fim = _filtro_periodo(request, sessoes)

	total_valor = sessoes.aggregate(total=Sum('valor_sessao')).get('total') or Decimal('0')
	total_minutos = sessoes.aggregate(total=Sum('duracao_minutos')).get('total') or 0

	contexto = {
		'form': form,
		'sessoes': sessoes[:300],
		'total_sessoes': sessoes.count(),
		'total_valor': total_valor,
		'total_horas': round(total_minutos / 60, 2),
		'data_inicio': data_inicio,
		'data_fim': data_fim,
	}
	return render(request, 'core/relatorio.html', contexto)


@login_required
def exportar_relatorio_pdf(request):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	sessoes = Sessao.objects.filter(atendimento__fisioterapeuta=fisioterapeuta).select_related(
		'atendimento',
		'atendimento__paciente',
		'atendimento__tipo_atendimento',
		'atendimento__empresa',
	)
	form, sessoes, data_inicio, data_fim = _filtro_periodo(request, sessoes)
	if not form.is_valid():
		return redirect('relatorio')

	response = HttpResponse(content_type='application/pdf')
	response['Content-Disposition'] = 'attachment; filename="relatorio_atendimentos.pdf"'
	pdf = canvas.Canvas(response, pagesize=A4)
	width, height = A4

	pdf.setTitle('Relatório de Atendimentos')
	pdf.setFont('Helvetica-Bold', 14)
	pdf.drawString(40, height - 40, 'Relatório de Atendimentos')
	pdf.setFont('Helvetica', 10)

	periodo = f'Período: {data_inicio or "início"} até {data_fim or "hoje"}'
	pdf.drawString(40, height - 60, periodo)
	pdf.drawString(40, height - 76, f'Profissional: {fisioterapeuta}')

	y = height - 105
	pdf.setFont('Helvetica-Bold', 9)
	pdf.drawString(40, y, 'Data')
	pdf.drawString(120, y, 'Paciente')
	pdf.drawString(260, y, 'Empresa')
	pdf.drawString(380, y, 'Tipo')
	pdf.drawString(500, y, 'Valor')
	y -= 14
	pdf.setFont('Helvetica', 8)

	total_valor = Decimal('0')
	for sessao in sessoes:
		total_valor += sessao.valor_sessao
		empresa_nome = sessao.atendimento.empresa.nome if sessao.atendimento.empresa else 'Particular'
		pdf.drawString(40, y, sessao.data_hora.strftime('%d/%m/%Y %H:%M'))
		pdf.drawString(120, y, sessao.atendimento.paciente.nome[:24])
		pdf.drawString(260, y, empresa_nome[:20])
		pdf.drawString(380, y, sessao.atendimento.tipo_atendimento.nome[:18])
		pdf.drawRightString(560, y, f'R$ {sessao.valor_sessao}')
		y -= 12
		if y < 50:
			pdf.showPage()
			pdf.setFont('Helvetica', 8)
			y = height - 40

	pdf.setFont('Helvetica-Bold', 10)
	pdf.drawString(40, max(y - 14, 30), f'Total de sessões: {sessoes.count()}')
	pdf.drawString(220, max(y - 14, 30), f'Total financeiro: R$ {total_valor}')
	pdf.save()
	return response


@login_required
def painel_financeiro(request):
	fisioterapeuta = _fisioterapeuta_do_usuario(request.user)
	sessoes = Sessao.objects.filter(atendimento__fisioterapeuta=fisioterapeuta).select_related(
		'atendimento',
		'atendimento__empresa',
		'atendimento__tipo_atendimento',
	)
	form, sessoes, data_inicio, data_fim = _filtro_periodo(request, sessoes)

	total_geral = Decimal('0')
	total_por_empresa = {}
	total_por_tipo = {}

	for sessao in sessoes:
		valor = sessao.valor_sessao
		total_geral += valor
		empresa_nome = sessao.atendimento.empresa.nome if sessao.atendimento.empresa else 'Particular'
		tipo_nome = sessao.atendimento.tipo_atendimento.nome
		total_por_empresa[empresa_nome] = total_por_empresa.get(empresa_nome, Decimal('0')) + valor
		total_por_tipo[tipo_nome] = total_por_tipo.get(tipo_nome, Decimal('0')) + valor

	resumo_empresa = sorted(total_por_empresa.items(), key=lambda item: item[1], reverse=True)
	resumo_tipo = sorted(total_por_tipo.items(), key=lambda item: item[1], reverse=True)

	contexto = {
		'form': form,
		'data_inicio': data_inicio,
		'data_fim': data_fim,
		'total_geral': total_geral,
		'resumo_empresa': resumo_empresa,
		'resumo_tipo': resumo_tipo,
	}
	return render(request, 'core/painel_financeiro.html', contexto)
