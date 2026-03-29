from django.urls import path

from . import views

urlpatterns = [
    path('', views.dashboard, name='dashboard'),
    path('registro/', views.registro, name='registro'),
    path('tipos-atendimento/', views.listar_criar_tipo_atendimento, name='tipos_atendimento'),
    path('tipos-atendimento/<int:tipo_id>/editar/', views.editar_tipo_atendimento, name='editar_tipo_atendimento'),
    path('tipos-atendimento/<int:tipo_id>/excluir/', views.excluir_tipo_atendimento, name='excluir_tipo_atendimento'),
    path('empresas/', views.listar_criar_empresa, name='empresas'),
    path('empresas/<int:empresa_id>/editar/', views.editar_empresa, name='editar_empresa'),
    path('empresas/<int:empresa_id>/excluir/', views.excluir_empresa, name='excluir_empresa'),
    path('pacientes/', views.listar_criar_paciente, name='pacientes'),
    path('pacientes/<int:paciente_id>/editar/', views.editar_paciente, name='editar_paciente'),
    path('pacientes/<int:paciente_id>/excluir/', views.excluir_paciente, name='excluir_paciente'),
    path('atendimentos/', views.listar_criar_atendimento, name='atendimentos'),
    path('atendimentos/<int:atendimento_id>/editar/', views.editar_atendimento, name='editar_atendimento'),
    path('atendimentos/<int:atendimento_id>/excluir/', views.excluir_atendimento, name='excluir_atendimento'),
    path('sessoes/', views.listar_criar_sessao, name='sessoes'),
    path('sessoes/<int:sessao_id>/editar/', views.editar_sessao, name='editar_sessao'),
    path('sessoes/<int:sessao_id>/excluir/', views.excluir_sessao, name='excluir_sessao'),
    path('bater-ponto/<int:atendimento_id>/', views.bater_ponto, name='bater_ponto'),
    path('relatorios/', views.relatorio_atendimentos, name='relatorio'),
    path('relatorios/exportar-pdf/', views.exportar_relatorio_pdf, name='exportar_relatorio_pdf'),
    path('financeiro/', views.painel_financeiro, name='painel_financeiro'),
]
