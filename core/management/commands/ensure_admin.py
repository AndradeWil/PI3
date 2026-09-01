import os

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from core.models import Fisioterapeuta


class Command(BaseCommand):
    help = 'Cria ou atualiza um superusuario a partir de variaveis de ambiente.'

    def handle(self, *args, **options):
        username = os.getenv('DJANGO_SUPERUSER_USERNAME', '').strip()
        email = os.getenv('DJANGO_SUPERUSER_EMAIL', '').strip()
        password = os.getenv('DJANGO_SUPERUSER_PASSWORD', '')

        if not username or not email or not password:
            self.stdout.write('Admin nao configurado; variaveis de ambiente ausentes.')
            return

        user_model = get_user_model()
        user, created = user_model.objects.get_or_create(
            username=username,
            defaults={'email': email},
        )
        user.email = email
        user.is_staff = True
        user.is_superuser = True
        user.set_password(password)
        user.save(update_fields=['email', 'is_staff', 'is_superuser', 'password'])
        Fisioterapeuta.objects.get_or_create(user=user)

        action = 'criado' if created else 'atualizado'
        self.stdout.write(self.style.SUCCESS(f'Administrador {action} com sucesso.'))