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
- cache local criptografado para leitura offline de pacientes e agendas ja sincronizadas;
- indicador visual quando a tela exibe dados offline e limpeza do cache no logout;
- fila criptografada para registro offline de sessoes, com retry idempotente;
- Inteligencia de Dados com KPIs, evolucao mensal, previsao baseline e estados de dados insuficientes;
- projetos nativos Android e iOS.

A URL padrao da API e `https://physiomanage.onrender.com/api/v1`. Outro ambiente
pode ser usado com `--dart-define=API_BASE_URL=https://servidor/api/v1`.

## Uso offline

Pacientes e dias da Agenda consultados com conexao ficam armazenados localmente
com criptografia AES. Se a API ficar indisponivel, o app exibe o ultimo snapshot
salvo e mostra a faixa `Dados offline`. O registro rapido de sessao pode ser
enfileirado sem conexao e sincronizado depois com a mesma chave idempotente.
Cadastro e edicao de dados ainda exigem conexao.

O cache clinico e apagado quando o usuario encerra a sessao.

Registros de sessão pendentes mantêm o mesmo UUID em todas as tentativas. O app
tenta sincronizá-los ao abrir Dashboard/Agenda e oferece a ação `Sincronizar
agora`. Erros permanentes de validação não são adicionados à fila.

## Inteligência de Dados

A tela apresenta indicadores operacionais reais e a série dos últimos seis
meses. A previsão disponível é um baseline de média móvel, não um diagnóstico
clínico nem uma previsão de ML validada. Na conta demo, deslocamentos e glosas
usam registros persistidos; evasão usa uma heurística de recência e faltas com
os fatores exibidos para cada paciente. Esses blocos são rotulados como
`Demonstração` ou `Heurística` na interface.

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
