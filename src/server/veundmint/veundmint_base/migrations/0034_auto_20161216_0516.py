# -*- coding: utf-8 -*-
# Generated by Django 1.10 on 2016-12-16 04:16
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('veundmint_base', '0033_auto_20161216_0511'),
    ]

    operations = [
        migrations.AlterField(
            model_name='question',
            name='maxpoints',
            field=models.PositiveSmallIntegerField(null=True),
        ),
        migrations.AlterField(
            model_name='question',
            name='uxid',
            field=models.CharField(max_length=100, null=True),
        ),
    ]
