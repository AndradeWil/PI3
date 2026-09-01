from rest_framework import serializers

from core.models import Paciente


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