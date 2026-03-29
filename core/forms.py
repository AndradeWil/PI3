from django import forms

from .models import Atendimento, Empresa, Paciente, Sessao, TipoAtendimento


class FisioterapeutaCadastroForm(forms.Form):
    nome = forms.CharField(max_length=150)
    email = forms.EmailField()
    crefito = forms.CharField(max_length=20, required=False)
    telefone = forms.CharField(max_length=20, required=False)
    cpf = forms.CharField(max_length=14, required=False)


class TipoAtendimentoForm(forms.ModelForm):
    class Meta:
        model = TipoAtendimento
        fields = ['nome', 'descricao', 'valor_padrao']


class EmpresaForm(forms.ModelForm):
    class Meta:
        model = Empresa
        fields = ['nome', 'contato', 'telefone', 'email']


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

    def __init__(self, *args, **kwargs):
        fisioterapeuta = kwargs.pop('fisioterapeuta')
        super().__init__(*args, **kwargs)
        self.fields['empresa'].queryset = Empresa.objects.filter(fisioterapeuta=fisioterapeuta).order_by('nome')


class AtendimentoForm(forms.ModelForm):
    class Meta:
        model = Atendimento
        fields = ['paciente', 'empresa', 'tipo_atendimento', 'valor_por_sessao', 'observacoes', 'ativo']

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
    data_inicio = forms.DateField(required=False, widget=forms.DateInput(attrs={'type': 'date'}))
    data_fim = forms.DateField(required=False, widget=forms.DateInput(attrs={'type': 'date'}))
