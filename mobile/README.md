# PhysioManage Mobile

Aplicativo Flutter para gestao de fisioterapia domiciliar, inicialmente voltado
ao Android e preparado para iOS.

## Estado atual

- fundacao em Clean Architecture;
- Riverpod para estado e injecao de dependencias;
- `go_router` para navegacao declarativa;
- tema claro/escuro alinhado ao sistema web;
- shell responsivo com barra inferior e `NavigationRail`;
- login JWT com refresh e armazenamento seguro de tokens;
- dashboard operacional conectado a API de producao;
- saudacao do Dashboard com o nome do fisioterapeuta autenticado;
- restauracao de sessao e logout com blacklist do refresh token;
- lista, busca, detalhe, cadastro e edicao de pacientes;
- lista, detalhe, cadastro, edicao e ativacao de atendimentos;
- cadastro, edicao e exclusao de empresas e tipos de atendimento;
- painel financeiro por periodo com KPIs e graficos por empresa e tipo;
- relatorio por periodo com resumo, sessoes e exportacao PDF autenticada;
- agenda diaria com selecao de data e acesso rapido ao paciente;
- registro rapido de sessao pelo Dashboard ou Agenda, com selecao do atendimento e protecao contra duplicidade;
- confirmacao de atendimento realizado e exclusao diretamente nos cards do Dashboard e Agenda;
- projetos nativos Android e iOS.

A URL padrao da API e `https://physiomanage.onrender.com/api/v1`. Outro ambiente
pode ser usado com `--dart-define=API_BASE_URL=https://servidor/api/v1`.

## Executar

```powershell
cd mobile
flutter pub get
flutter run
```

Caso o Flutter ainda nao esteja no `PATH` desta maquina:

```powershell
& "$env:LOCALAPPDATA\Programs\flutter\bin\flutter.bat" pub get
& "$env:LOCALAPPDATA\Programs\flutter\bin\flutter.bat" run
```

## Qualidade

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

O APK de desenvolvimento e gerado em
`build/app/outputs/flutter-apk/app-debug.apk`.

## Estrutura inicial

```text
lib/
|-- app/                 # bootstrap, router, shell e tema
`-- features/
	`-- dashboard/
		|-- application/
		|-- data/
		|-- domain/
		`-- presentation/
```

Consulte o plano completo em
[`../docs/ARQUITETURA_PHYSIOMANAGE_MOBILE.md`](../docs/ARQUITETURA_PHYSIOMANAGE_MOBILE.md).
