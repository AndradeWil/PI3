# PI3 - Sistema de Gestão de Atendimentos em Fisioterapia

Projeto acadêmico desenvolvido com Django para gerenciamento de pacientes, atendimentos, sessões, relatórios e painel financeiro.

## Tecnologias

- Python 3.12+
- Django 6.0.3
- SQLite3 (banco local, arquivo `db.sqlite3`)
- ReportLab (geração de PDF)

## Funcionalidades principais

- Cadastro e autenticação de usuário (fisioterapeuta)
- Cadastro de tipos de atendimento
- Cadastro de empresas
- Cadastro de pacientes
- Cadastro e gerenciamento de atendimentos
- Registro de sessões (incluindo "bater ponto")
- Relatório por período
- Exportação de relatório em PDF
- Painel financeiro por empresa e tipo de atendimento

## Evolução mobile (PI4)

Consulte [Arquitetura e Plano de Execução do PhysioManage Mobile](docs/ARQUITETURA_PHYSIOMANAGE_MOBILE.md) para a arquitetura Flutter, estratégia de integração, módulo de Inteligência de Dados, roadmap, backlog e plano de testes.

O cliente Flutter está em [mobile/](mobile/) e utiliza por padrão a API publicada em `https://physiomanage.onrender.com/api/v1`.

### API mobile v1

- `POST /api/v1/auth/token/`: login e emissão de JWT.
- `POST /api/v1/auth/token/refresh/`: renovação e rotação do token.
- `POST /api/v1/auth/logout/`: logout e bloqueio do refresh token.
- `GET /api/v1/me/`: perfil do fisioterapeuta autenticado.
- `GET /api/v1/dashboard/`: indicadores e agenda isolados por fisioterapeuta.
- `GET, POST /api/v1/pacientes/`: lista paginada, busca e cadastro de pacientes.
- `GET, PATCH /api/v1/pacientes/{id}/`: consulta e edição de paciente.
- `GET /api/v1/sessoes/?data=AAAA-MM-DD`: agenda diária do fisioterapeuta.
- `GET /api/v1/atendimentos/ativos/`: atendimentos disponíveis para registro rápido.
- `GET, POST /api/v1/atendimentos/`: lista e cadastro de atendimentos.
- `GET, PATCH /api/v1/atendimentos/{id}/`: detalhe e edição de atendimento.
- `GET /api/v1/atendimentos/opcoes/`: pacientes, empresas e tipos disponíveis ao formulário.
- `POST /api/v1/atendimentos/{id}/bater-ponto/`: registra sessão com `Idempotency-Key` UUID.

As views HTML e a autenticação por sessão continuam disponíveis para a plataforma web.

### Administrador no Render

O `build.sh` executa o comando idempotente `ensure_admin`. Configure no painel **Environment** do serviço:

- `DJANGO_SUPERUSER_USERNAME`
- `DJANGO_SUPERUSER_EMAIL`
- `DJANGO_SUPERUSER_PASSWORD`

No próximo deploy, o usuário será criado ou atualizado como administrador. Se alguma variável estiver ausente, o build continua sem criar usuário. A senha deve existir somente nas variáveis secretas do Render, nunca no repositório.

### Usuário e massa de demonstração

Para manter uma conta pronta para apresentações, configure também no **Environment** do Render:

- `DJANGO_DEMO_USERNAME`
- `DJANGO_DEMO_EMAIL`
- `DJANGO_DEMO_PASSWORD`

O `build.sh` executa `ensure_demo_data` e cria ou atualiza uma conta de fisioterapeuta com empresa, tipos de atendimento, quatro pacientes, atendimentos ativos e sessões de histórico/agenda. A operação é idempotente: novos deploys atualizam a massa marcada como demonstração sem duplicá-la. Use credenciais próprias para apresentação e não publique a senha no README, nos slides ou no Git.

> O filesystem dos serviços gratuitos do Render é efêmero. Um banco SQLite armazenado nele pode perder usuários e dados em reinicializações ou novos deploys. Para dados persistentes, use PostgreSQL externo/persistente e configure o Django por variável de ambiente.

## Como rodar o projeto (passo a passo)

### 1. Clonar o repositório

```bash
git clone <URL_DO_REPOSITORIO>
cd PI3
```

### 2. Criar e ativar ambiente virtual

#### Windows (PowerShell)

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Se houver bloqueio de execução de scripts no PowerShell:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Windows (CMD)

```bat
python -m venv .venv
.venv\Scripts\activate.bat
```

#### Linux/macOS

```bash
python3 -m venv .venv
source .venv/bin/activate
```

### 3. Instalar dependências

```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Alternativa (instalação direta):

```bash
pip install Django==6.0.3 reportlab==4.4.4
```

### 4. Aplicar migrações do banco de dados

```bash
python manage.py migrate
```

### 5. (Opcional) Criar usuário administrador

```bash
python manage.py createsuperuser
```

### 6. Executar o servidor

```bash
python manage.py runserver
```

Com o servidor em execução, abra:

- App: http://127.0.0.1:8000/
- Admin: http://127.0.0.1:8000/admin/

## Primeiro acesso

- Se ainda não houver usuário, acesse `http://127.0.0.1:8000/registro/` para registrar um fisioterapeuta.
- Login padrão do Django: `http://127.0.0.1:8000/accounts/login/`.

## Comandos úteis

### Rodar testes

```bash
python manage.py test
```

### Gerar novas migrações (quando alterar models)

```bash
python manage.py makemigrations
python manage.py migrate
```

### Coletar arquivos estáticos (uso mais comum em deploy)

```bash
python manage.py collectstatic
```

## Estrutura resumida

```text
PI3/
|-- manage.py
|-- db.sqlite3
|-- config/         # Configurações do projeto Django
|-- core/           # App principal (models, views, forms, urls)
|-- templates/      # Templates HTML
`-- static/         # CSS e imagens
```

## Solução de problemas comuns

- Erro "No module named django":
  - Verifique se o ambiente virtual está ativado.
  - Reinstale dependências com `pip install -r requirements.txt`.

- Porta 8000 em uso:
  - Rode em outra porta: `python manage.py runserver 8001`.

- Alterou models e recebeu erro de tabela/coluna:
  - Execute `python manage.py makemigrations` e depois `python manage.py migrate`.

## Observações

- Este projeto está configurado para ambiente de desenvolvimento (`DEBUG = True`).
- O banco SQLite local fica em `db.sqlite3`.
- O idioma está configurado para Português (Brasil) e fuso horário `America/Sao_Paulo`.

## Testes automatizados

### Ferramenta utilizada

- Django Test Framework (baseado em `unittest`), via `django.test.TestCase`.

### O que é coberto

- Modelos: relacionamentos, `__str__`, integridade e regras de unicidade.
- Formulários: filtragem de campos por fisioterapeuta logado.
- Views: autenticação, dashboard, CRUDs principais, bater ponto, relatório, exportação em PDF e painel financeiro.

### Passo a passo para executar os testes

1. Ative o ambiente virtual.

Windows (PowerShell):

```powershell
.\.venv\Scripts\Activate.ps1
```

Linux/macOS:

```bash
source .venv/bin/activate
```

2. Garanta as dependências instaladas:

```bash
pip install -r requirements.txt
```

3. Execute a suíte completa:

```bash
python manage.py test
```

4. (Opcional) Execute apenas os testes do app principal:

```bash
python manage.py test core
```

5. (Opcional) Execute uma classe específica de testes:

```bash
python manage.py test core.tests.ViewTests
```

### Resultado esperado

- O Django cria um banco temporário de testes, executa os cenários e remove esse banco ao final.
- Em caso de sucesso, o terminal exibirá `OK` com a quantidade de testes executados.
