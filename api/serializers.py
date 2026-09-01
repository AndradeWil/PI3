from rest_framework import serializers

from core.models import Atendimento, Empresa, Paciente, Sessao, TipoAtendimento


class PacienteSerializer(serializers.ModelSerializer):
    empresa_nome = serializers.CharField(source='empresa.nome', read_only=True)

    class Meta:
        model = Paciente
        fields = (
            'id',
            'nome',
            'idade',
            'telefone',
            'email',
            'endereco',
            'quadro_clinico',
            'frequencia_por_dia',
            'empresa',
            'empresa_nome',
        )

    def validate_empresa(self, empresa):
        if empresa is None:
            return None
        fisioterapeuta_id = getattr(self.context['request'].user, 'fisioterapeuta', None)
        if fisioterapeuta_id is None or empresa.fisioterapeuta_id != fisioterapeuta_id.id:
            raise serializers.ValidationError('Empresa invalida para este fisioterapeuta.')
        return empresa


class SessaoSerializer(serializers.ModelSerializer):
    paciente_id = serializers.IntegerField(source='atendimento.paciente_id', read_only=True)
    paciente_nome = serializers.CharField(source='atendimento.paciente.nome', read_only=True)
    endereco = serializers.CharField(source='atendimento.paciente.endereco', read_only=True)
    tipo_atendimento = serializers.CharField(source='atendimento.tipo_atendimento.nome', read_only=True)

    class Meta:
        model = Sessao
        fields = (
            'id',
            'atendimento',
            'paciente_id',
            'paciente_nome',
            'endereco',
            'tipo_atendimento',
            'data_hora',
            'duracao_minutos',
            'valor_sessao',
            'compareceu',
            'observacoes',
        )


class SessaoStatusSerializer(serializers.ModelSerializer):
    class Meta:
        model = Sessao
        fields = ('id', 'compareceu')
        read_only_fields = ('id',)


class AtendimentoResumoSerializer(serializers.ModelSerializer):
    paciente_nome = serializers.CharField(source='paciente.nome', read_only=True)
    tipo_atendimento_nome = serializers.CharField(source='tipo_atendimento.nome', read_only=True)

    class Meta:
        model = Atendimento
        fields = (
            'id',
            'paciente_nome',
            'tipo_atendimento_nome',
            'valor_por_sessao',
        )


class AtendimentoSerializer(serializers.ModelSerializer):
    paciente_nome = serializers.CharField(source='paciente.nome', read_only=True)
    empresa_nome = serializers.CharField(source='empresa.nome', read_only=True)
    tipo_atendimento_nome = serializers.CharField(source='tipo_atendimento.nome', read_only=True)

    class Meta:
        model = Atendimento
        fields = (
            'id',
            'paciente',
            'paciente_nome',
            'empresa',
            'empresa_nome',
            'tipo_atendimento',
            'tipo_atendimento_nome',
            'valor_por_sessao',
            'observacoes',
            'ativo',
            'criado_em',
        )
        read_only_fields = ('criado_em',)

    def validate(self, attrs):
        therapist = getattr(self.context['request'].user, 'fisioterapeuta', None)
        if therapist is None:
            raise serializers.ValidationError('Perfil de fisioterapeuta nao encontrado.')
        patient = attrs.get('paciente', getattr(self.instance, 'paciente', None))
        company = attrs.get('empresa', getattr(self.instance, 'empresa', None))
        appointment_type = attrs.get(
            'tipo_atendimento',
            getattr(self.instance, 'tipo_atendimento', None),
        )
        if patient is not None and patient.fisioterapeuta_id != therapist.id:
            raise serializers.ValidationError({'paciente': 'Paciente invalido.'})
        if company is not None and company.fisioterapeuta_id != therapist.id:
            raise serializers.ValidationError({'empresa': 'Empresa invalida.'})
        if appointment_type is not None and appointment_type.fisioterapeuta_id != therapist.id:
            raise serializers.ValidationError({'tipo_atendimento': 'Tipo invalido.'})
        return attrs


class EmpresaOpcaoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = ('id', 'nome')


class TipoAtendimentoOpcaoSerializer(serializers.ModelSerializer):
    class Meta:
        model = TipoAtendimento
        fields = ('id', 'nome', 'valor_padrao')


class EmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = ('id', 'nome', 'contato', 'telefone', 'email')

    def validate_nome(self, value):
        therapist = self.context['request'].user.fisioterapeuta
        queryset = Empresa.objects.filter(fisioterapeuta=therapist, nome__iexact=value.strip())
        if self.instance is not None:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError('Ja existe uma empresa com este nome.')
        return value.strip()


class TipoAtendimentoSerializer(serializers.ModelSerializer):
    class Meta:
        model = TipoAtendimento
        fields = ('id', 'nome', 'descricao', 'valor_padrao')

    def validate_nome(self, value):
        therapist = self.context['request'].user.fisioterapeuta
        queryset = TipoAtendimento.objects.filter(
            fisioterapeuta=therapist,
            nome__iexact=value.strip(),
        )
        if self.instance is not None:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError('Ja existe um tipo com este nome.')
        return value.strip()