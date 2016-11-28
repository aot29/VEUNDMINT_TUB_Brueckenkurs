# -*- coding: utf-8 -*-
# Generated by Django 1.10 on 2016-09-19 12:07
from __future__ import unicode_literals

import datetime
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('veundmint_base', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='Score',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(default=datetime.datetime.now)),
                ('question_id', models.CharField(max_length=50)),
                ('siteuxid', models.CharField(max_length=200)),
                ('section', models.PositiveSmallIntegerField()),
                ('maxpoints', models.PositiveSmallIntegerField()),
                ('points', models.PositiveSmallIntegerField()),
                ('value', models.PositiveSmallIntegerField()),
                ('rawinput', models.CharField(max_length=1000)),
                ('state', models.PositiveSmallIntegerField()),
                ('intest', models.BooleanField()),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'abstract': False,
            },
        ),
        migrations.AddField(
            model_name='websiteaction',
            name='updated_at',
            field=models.DateTimeField(default=datetime.datetime.now),
        ),
    ]
