# -*- coding: utf-8 -*-
# Generated by Django 1.10 on 2016-09-20 14:37
from __future__ import unicode_literals

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('veundmint_base', '0008_auto_20160920_1629'),
    ]

    operations = [
        migrations.AlterField(
            model_name='score',
            name='question',
            field=models.ForeignKey(blank=True, default=None, null=True, on_delete=django.db.models.deletion.CASCADE, to='veundmint_base.Question', unique=True),
        ),
    ]
