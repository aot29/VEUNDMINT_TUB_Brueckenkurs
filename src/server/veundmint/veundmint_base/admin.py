from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User
from veundmint_base.models import Site, Score, Question, UserFeedback, CourseProfile, Statistics


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

class QuestionInline(admin.TabularInline):
	model = Question
	can_delete = False
	readonly_fields = ('question_id', 'site', 'maxpoints', 'section', 'type', 'intest')

	def has_add_permission(self, request):
		return False

@admin.register(Site)
class SiteAdmin(admin.ModelAdmin):
	inlines = (QuestionInline, )

@admin.register(Statistics)
class StatisticsAdmin(admin.ModelAdmin):
    list_display = ('user', 'site', 'millis', 'points' )
    list_filter = ('user', 'site', 'points' )

@admin.register(Score)
class ScoreAdmin(admin.ModelAdmin):
    list_display = ('user', 'points', 'rawinput', 'question' )
    list_filter = ('user', 'points', 'rawinput', 'question__question_id' )
    search_fields = ['user__email', 'question__question_id']

@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
	list_display = ('question_id', 'site', 'maxpoints', 'section')
	list_filter = ('question_id', 'site', 'maxpoints')

@admin.register(UserFeedback)
class UserFeedbackAdmin(admin.ModelAdmin):
    list_display = ('created_at', 'rawfeedback')
