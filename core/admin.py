from django.contrib import admin

from .models import Atendimento, Empresa, Fisioterapeuta, Paciente, Sessao, TipoAtendimento

admin.site.register(Fisioterapeuta)
admin.site.register(TipoAtendimento)
admin.site.register(Empresa)
admin.site.register(Paciente)
admin.site.register(Atendimento)
admin.site.register(Sessao)
