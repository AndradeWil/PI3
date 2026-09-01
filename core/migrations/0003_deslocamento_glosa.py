from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):
    dependencies = [
        ('core', '0002_sessao_idempotency_key'),
    ]

    operations = [
        migrations.CreateModel(
            name='Deslocamento',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('distancia_km', models.DecimalField(decimal_places=2, max_digits=8)),
                ('custo', models.DecimalField(decimal_places=2, max_digits=10)),
                ('sessao', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='deslocamento', to='core.sessao')),
            ],
        ),
        migrations.CreateModel(
            name='Glosa',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('operadora', models.CharField(max_length=150)),
                ('valor', models.DecimalField(decimal_places=2, max_digits=10)),
                ('motivo', models.CharField(blank=True, max_length=255)),
                ('status', models.CharField(choices=[('pendente', 'Pendente'), ('confirmada', 'Confirmada'), ('revertida', 'Revertida')], default='pendente', max_length=20)),
                ('sessao', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='glosas', to='core.sessao')),
            ],
        ),
    ]