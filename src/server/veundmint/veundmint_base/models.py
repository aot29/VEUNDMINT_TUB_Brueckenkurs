from django.db import models
from django.conf import settings
from django.utils import timezone
from django.contrib.auth import get_user_model

TESTUSER_USERNAME = 'testrunner'
TESTUSER_PASSWORD = '<>87c`}X&c8)2]Ja6E2cLD%yr]*A$^3E'

class DateSensitiveModel(models.Model):
	created_at = models.DateTimeField(auto_now_add=True)
	updated_at = models.DateTimeField(default=timezone.now)

	class Meta:
		abstract = True

# Create your models here.
class WebsiteAction(DateSensitiveModel):
	action_id = models.CharField(max_length=200)
	ip_address = models.CharField(max_length=200)
	browser_type = models.CharField(max_length=1000)

class Question(DateSensitiveModel):
	question_id = models.CharField(max_length=50)
	siteuxid = models.CharField(max_length=200)
	section = models.PositiveSmallIntegerField()
	maxpoints = models.PositiveSmallIntegerField()
	intest = models.BooleanField(default=False)
	type = models.PositiveSmallIntegerField()


class Score(DateSensitiveModel):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, related_name="scores")

    #this should be used later with the model defined above, by now, for getting
    #started we just copied the model structure form old scores array
    #question = models.ForeignKey(Question, blank=True, default=None, null=True)
    q_id = models.CharField(max_length=50, default='')
    siteuxid = models.CharField(max_length=200, default='')
    section = models.PositiveSmallIntegerField(default = 0)
    maxpoints = models.PositiveSmallIntegerField(default=0)
    intest = models.BooleanField(default=False)
    ### end

    points = models.PositiveSmallIntegerField(null=True)
    value = models.PositiveSmallIntegerField(blank=True, null=True)

    rawinput = models.CharField(max_length=1000, blank=True)
    state = models.PositiveSmallIntegerField(blank=True, null=True)

    uxid = models.CharField(max_length=100, blank=True)

    class Meta:
    	unique_together = ("user", "q_id")

class Foo(models.Model):
    siteuxid = models.CharField(max_length=200, default='')
    intest = models.BooleanField(default=False)
    
def get_test_user():
	user, created = get_user_model.objects.get_or_create(username=TESTUSER_USERNAME)
	user.set_password(TESTUSER_PASSWORD)
	user.save
