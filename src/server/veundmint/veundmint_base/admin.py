from django.contrib import admin
from veundmint_base.models import Score, Question

# Register your models here.
@admin.register(Score)
class ScoreAdmin(admin.ModelAdmin):
    list_display = ('user', 'q_id', 'points', 'rawinput', 'intest')
    list_filter = ('user', 'q_id', 'intest')
    search_fields = ['user__email', 'q_id']

@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
	pass
