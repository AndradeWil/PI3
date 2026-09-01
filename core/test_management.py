from io import StringIO
from unittest.mock import patch

from django.contrib.auth.models import User
from django.core.management import call_command
from django.test import TestCase


class EnsureAdminCommandTests(TestCase):
    @patch.dict('os.environ', {}, clear=True)
    def test_does_nothing_without_environment_variables(self):
        output = StringIO()

        call_command('ensure_admin', stdout=output)

        self.assertFalse(User.objects.exists())
        self.assertIn('variaveis de ambiente ausentes', output.getvalue())

    @patch.dict('os.environ', {
        'DJANGO_SUPERUSER_USERNAME': 'admin-render',
        'DJANGO_SUPERUSER_EMAIL': 'admin@example.com',
        'DJANGO_SUPERUSER_PASSWORD': 'senha-segura-123',
    }, clear=True)
    def test_creates_and_updates_superuser_idempotently(self):
        call_command('ensure_admin', stdout=StringIO())
        call_command('ensure_admin', stdout=StringIO())

        self.assertEqual(User.objects.count(), 1)
        user = User.objects.get(username='admin-render')
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)
        self.assertTrue(user.check_password('senha-segura-123'))