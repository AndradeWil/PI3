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
