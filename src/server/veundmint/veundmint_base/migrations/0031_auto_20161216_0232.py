# -*- coding: utf-8 -*-
# Generated by Django 1.10 on 2016-12-16 01:32
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('veundmint_base', '0030_statistics_points'),
    ]

    operations = [
        migrations.AlterField(
            model_name='site',
            name='site_id',
            field=models.CharField(max_length=300),
        ),
    ]
