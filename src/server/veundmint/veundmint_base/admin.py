from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User
from veundmint_base.models import Site, Score, Question, UserFeedback, CourseProfile


# Define an inline admin descriptor for Employee model
# which acts a bit like a singleton
class ProfileInline(admin.StackedInline):
    model = CourseProfile
    can_delete = False
    verbose_name_plural = 'profiles'

# Define a new User admin
class UserAdmin(BaseUserAdmin):
    inlines = (ProfileInline, )

# Re-register UserAdmin
admin.site.unregister(User)
admin.site.register(User, UserAdmin)

@admin.register(Site)
class SiteAdmin(admin.ModelAdmin):
	pass

@admin.register(Score)
class ScoreAdmin(admin.ModelAdmin):
    #list_display = ('user', 'q_id', 'points', 'rawinput', 'intest', )
    #list_filter = ('user', 'q_id', 'intest', )
    search_fields = ['user__email', 'question__question_id']

@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
	pass

@admin.register(UserFeedback)
class UserFeedbackAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'rawfeedback')
