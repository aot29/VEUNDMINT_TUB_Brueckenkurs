# -*- coding: utf-8 -*-
# Generated by Django 1.10 on 2016-09-20 14:29
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('veundmint_base', '0007_auto_20160920_1629'),
    ]

    operations = [
        migrations.AlterField(
            model_name='score',
            name='value',
            field=models.PositiveSmallIntegerField(blank=True, null=True),
        ),
    ]
