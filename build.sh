#!/bin/bash
set -o errexit

pip install -r requirements.txt

python manage.py migrate
python manage.py ensure_admin
python manage.py ensure_demo_data
python manage.py collectstatic --no-input
