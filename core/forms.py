from django import forms

from .models import Atendimento, Empresa, Paciente, Sessao, TipoAtendimento


class FisioterapeutaCadastroForm(forms.Form):
    nome = forms.CharField(max_length=150, label='Nome')
    email = forms.EmailField(label='E-mail')
    crefito = forms.CharField(max_length=20, required=False, label='CREFITO')
    telefone = forms.CharField(max_length=20, required=False, label='Telefone')
    cpf = forms.CharField(max_length=14, required=False, label='CPF')


class TipoAtendimentoForm(forms.ModelForm):
    class Meta:
        model = TipoAtendimento
        fields = ['nome', 'descricao', 'valor_padrao']
        labels = {
            'nome': 'Nome',
            'descricao': 'Descrição',
            'valor_padrao': 'Valor padrão',
        }


class EmpresaForm(forms.ModelForm):
    class Meta:
        model = Empresa
        fields = ['nome', 'contato', 'telefone', 'email']
        labels = {
            'nome': 'Nome',
            'contato': 'Contato',
            'telefone': 'Telefone',
            'email': 'E-mail',
        }


class PacienteForm(forms.ModelForm):
    class Meta:
        model = Paciente
        fields = [
            'nome',
            'idade',
            'telefone',
            'email',
            'endereco',
            'quadro_clinico',
            'frequencia_por_dia',
            'empresa',
        ]
        labels = {
            'nome': 'Nome',
            'idade': 'Idade',
            'telefone': 'Telefone',
            'email': 'E-mail',
            'endereco': 'Endereço',
            'quadro_clinico': 'Quadro clínico',
            'frequencia_por_dia': 'Frequência por dia',
            'empresa': 'Empresa',
        }

    def __init__(self, *args, **kwargs):
        fisioterapeuta = kwargs.pop('fisioterapeuta')
        super().__init__(*args, **kwargs)
        self.fields['empresa'].queryset = Empresa.objects.filter(fisioterapeuta=fisioterapeuta).order_by('nome')


class AtendimentoForm(forms.ModelForm):
    class Meta:
        model = Atendimento
        fields = ['paciente', 'empresa', 'tipo_atendimento', 'valor_por_sessao', 'observacoes', 'ativo']
        labels = {
            'paciente': 'Paciente',
            'empresa': 'Empresa',
            'tipo_atendimento': 'Tipo de atendimento',
            'valor_por_sessao': 'Valor por sessão',
            'observacoes': 'Observações',
            'ativo': 'Ativo',
        }

    def __init__(self, *args, **kwargs):
        fisioterapeuta = kwargs.pop('fisioterapeuta')
        super().__init__(*args, **kwargs)
        self.fields['paciente'].queryset = Paciente.objects.filter(fisioterapeuta=fisioterapeuta).order_by('nome')
        self.fields['empresa'].queryset = Empresa.objects.filter(fisioterapeuta=fisioterapeuta).order_by('nome')
        self.fields['tipo_atendimento'].queryset = TipoAtendimento.objects.filter(fisioterapeuta=fisioterapeuta).order_by('nome')


class SessaoForm(forms.ModelForm):
    class Meta:
        model = Sessao
        fields = ['atendimento', 'data_hora', 'duracao_minutos', 'valor_sessao', 'compareceu', 'observacoes']
        labels = {
            'atendimento': 'Atendimento',
            'data_hora': 'Data e hora',
            'duracao_minutos': 'Duração (minutos)',
            'valor_sessao': 'Valor da sessão',
            'compareceu': 'Compareceu',
            'observacoes': 'Observações',
        }
        widgets = {
            'data_hora': forms.DateTimeInput(attrs={'type': 'datetime-local'}),
        }

    def __init__(self, *args, **kwargs):
        fisioterapeuta = kwargs.pop('fisioterapeuta')
        super().__init__(*args, **kwargs)
        self.fields['atendimento'].queryset = Atendimento.objects.filter(fisioterapeuta=fisioterapeuta, ativo=True).order_by(
            'paciente__nome'
        )


class RelatorioPeriodoForm(forms.Form):
    data_inicio = forms.DateField(required=False, label='Data de início', widget=forms.DateInput(attrs={'type': 'date'}))
    data_fim = forms.DateField(required=False, label='Data de fim', widget=forms.DateInput(attrs={'type': 'date'}))
