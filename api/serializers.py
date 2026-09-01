from rest_framework import serializers

from core.models import Paciente, Sessao


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