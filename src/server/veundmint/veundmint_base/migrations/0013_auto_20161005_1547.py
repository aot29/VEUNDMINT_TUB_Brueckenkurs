# -*- coding: utf-8 -*-
# Generated by Django 1.10 on 2016-10-05 13:47
from __future__ import unicode_literals

from django.conf import settings
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('veundmint_base', '0012_auto_20161005_1520'),
    ]

    operations = [
        migrations.AlterUniqueTogether(
            name='score',
            unique_together=set([('user', 'q_id')]),
        ),
    ]
