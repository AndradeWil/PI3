# PI3 - Sistema de Gestao de Atendimentos em Fisioterapia

Projeto academico desenvolvido com Django para gerenciamento de pacientes, atendimentos, sessoes, relatorios e painel financeiro.

## Tecnologias

- Python 3.12+
- Django 6.0.3
- SQLite3 (banco local, arquivo `db.sqlite3`)
- ReportLab (geracao de PDF)

## Funcionalidades principais

- Cadastro e autenticacao de usuario (fisioterapeuta)
- Cadastro de tipos de atendimento
- Cadastro de empresas
- Cadastro de pacientes
- Cadastro e gerenciamento de atendimentos
- Registro de sessoes (incluindo "bater ponto")
- Relatorio por periodo
- Exportacao de relatorio em PDF
- Painel financeiro por empresa e tipo de atendimento

## Como rodar o projeto (passo a passo)

### 1. Clonar o repositorio

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

Se houver bloqueio de execucao de scripts no PowerShell:

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

### 3. Instalar dependencias

```bash
python -m pip install --upgrade pip
pip install -r requirements.txt
```

Alternativa (instalacao direta):

```bash
pip install Django==6.0.3 reportlab==4.4.4
```

### 4. Aplicar migracoes do banco de dados

```bash
python manage.py migrate
```

### 5. (Opcional) Criar usuario administrador

```bash
python manage.py createsuperuser
```

### 6. Executar o servidor

```bash
python manage.py runserver
```

Com o servidor em execucao, abra:

- App: http://127.0.0.1:8000/
- Admin: http://127.0.0.1:8000/admin/

## Primeiro acesso

- Se ainda nao houver usuario, acesse `http://127.0.0.1:8000/registro/` para registrar um fisioterapeuta.
- Login padrao do Django: `http://127.0.0.1:8000/accounts/login/`.

## Comandos uteis

### Rodar testes

```bash
python manage.py test
```

### Gerar novas migracoes (quando alterar models)

```bash
python manage.py makemigrations
python manage.py migrate
```

### Coletar arquivos estaticos (uso mais comum em deploy)

```bash
python manage.py collectstatic
```

## Estrutura resumida

```text
PI3/
|-- manage.py
|-- db.sqlite3
|-- config/         # Configuracoes do projeto Django
|-- core/           # App principal (models, views, forms, urls)
|-- templates/      # Templates HTML
`-- static/         # CSS e imagens
```

## Solucao de problemas comuns

- Erro "No module named django":
  - Verifique se o ambiente virtual esta ativado.
  - Reinstale dependencias com `pip install -r requirements.txt`.

- Porta 8000 em uso:
  - Rode em outra porta: `python manage.py runserver 8001`.

- Alterou models e recebeu erro de tabela/coluna:
  - Execute `python manage.py makemigrations` e depois `python manage.py migrate`.

## Observacoes

- Este projeto esta configurado para ambiente de desenvolvimento (`DEBUG = True`).
- O banco SQLite local fica em `db.sqlite3`.
- O idioma esta configurado para Portugues (Brasil) e fuso horario `America/Sao_Paulo`.
