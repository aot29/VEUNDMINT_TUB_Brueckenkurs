from django.contrib.auth.models import User
from django.db import models
from django.conf import settings
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.db.models.signals import post_save
from django.dispatch import receiver

TESTUSER_USERNAME = 'testrunner'
TESTUSER_PASSWORD = '<>87c`}X&c8)2]Ja6E2cLD%yr]*A$^3E'

class DateSensitiveModel(models.Model):
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(auto_now=True)

	class Meta:
		abstract = True

class CourseProfile(models.Model):
	user = models.OneToOneField(User, related_name="profile", on_delete=models.CASCADE)
	university = models.CharField(max_length=200)
	study = models.CharField(max_length=200)

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        CourseProfile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    instance.profile.save()

class WebsiteAction(DateSensitiveModel):
	action_id = models.CharField(max_length=200)
	ip_address = models.CharField(max_length=200)
	browser_type = models.CharField(max_length=1000)

class UserFeedback(DateSensitiveModel):
	rawfeedback = models.TextField(blank=True)

class Site(DateSensitiveModel):
	site_id = models.CharField(max_length=300, blank=False)
	users = models.ManyToManyField(
		settings.AUTH_USER_MODEL,
		through='Statistics',
		through_fields=('site', 'user'),
	)

class Question(DateSensitiveModel):
	question_id = models.CharField(max_length=50)
	site = models.ForeignKey(Site, null=True, on_delete=models.SET_NULL, related_name="questions")
	section = models.PositiveSmallIntegerField()
	maxpoints = models.PositiveSmallIntegerField()
	intest = models.BooleanField(default=False)
	type = models.PositiveSmallIntegerField(null=True)

	def __str__(self):
		return self.question_id

class Statistics(DateSensitiveModel):
	user = models.ForeignKey(settings.AUTH_USER_MODEL, null=True, on_delete=models.SET_NULL, related_name="statistics")
	site = models.ForeignKey(Site, null=True, on_delete=models.SET_NULL)
	millis = models.PositiveIntegerField(null=True, default=0)
	points = models.PositiveIntegerField(null=True, default=0)

class Score(DateSensitiveModel):
	user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="scores")

	#this should be used later with the model defined above, by now, for getting
	#started we just copied the model structure form old scores array
	question = models.ForeignKey(Question, null=True, on_delete=models.SET_NULL)
	# q_id = models.CharField(max_length=50, default='')
	# siteuxid = models.CharField(max_length=200, default='')
	# section = models.PositiveSmallIntegerField(default = 0)
	# maxpoints = models.PositiveSmallIntegerField(default=0)
	# intest = models.BooleanField(default=False)
	### end

	points = models.PositiveSmallIntegerField(null=True, default=0)
	value = models.PositiveSmallIntegerField(blank=True, null=True)

	rawinput = models.CharField(max_length=1000, blank=True)
	state = models.PositiveSmallIntegerField(blank=True, null=True)

	#uxid = models.CharField(max_length=100, blank=True)

	class Meta:
		unique_together = ("user", "question")

class Foo(models.Model):
    siteuxid = models.CharField(max_length=200, default='')
    intest = models.BooleanField(default=False)



def get_test_user():
	user, created = get_user_model.objects.get_or_create(username=TESTUSER_USERNAME)
	user.set_password(TESTUSER_PASSWORD)
	user.save()
