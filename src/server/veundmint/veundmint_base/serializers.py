from rest_framework import serializers
from django.contrib.auth import get_user_model
from veundmint_base.models import WebsiteAction, Question, Score, UserFeedback, CourseProfile, Site, Statistics
from rest_auth.registration.serializers import RegisterSerializer
from rest_auth.serializers import UserDetailsSerializer, JWTSerializer, TokenSerializer
from rest_auth.models import TokenModel
from django.db import models
from rest_framework.utils import html
from rest_framework.exceptions import ValidationError
from rest_framework.settings import api_settings

class SiteListSerializer(serializers.ListSerializer):

	def to_representation(self, data):
		"""
		List of object instances -> dict of dicts of primitive datatypes.
		"""
		# Dealing with nested relationships, data can be a Manager,
		# so, first get a queryset from the Manager if needed
		iterable = data.all() if isinstance(data, models.Manager) else data

		return {
			item.site_id : self.child.to_representation(item) for item in iterable
		}

# Serializers define the API representation.
class WebsiteActionSerializer(serializers.HyperlinkedModelSerializer):
	class Meta:
		model = WebsiteAction
		fields = ('action_id', 'created_at', 'browser_type', 'ip_address')

class UserFeedbackSerializer(serializers.ModelSerializer):
	class Meta:
		model = UserFeedback
		fields = ('rawfeedback', )

class SiteSerializer(serializers.ModelSerializer):

	site_id = serializers.CharField(required=True, allow_blank=False)

	def validate(self, data):
		print('siteSerializer data', data)
		return data

	def create(self, validated_data):
		print ('siteSerializer validated data', validated_data)
		return super(SiteSerializer, self).create(validated_data)

	def update(self, instance, validated_data):
		print ('siteSerializer update validated data', validated_data)
		return super(SiteSerializer, self).update(instance, validated_data)

	class Meta:
		model = Site
		fields = ('site_id', )

class QuestionSerializer(serializers.ModelSerializer):

	site = SiteSerializer()

	def validate(self, data):
		print('questionSerializer data', data)
		return data

	def create(self, validated_data):
		print ('questionSerializer validated data', validated_data)
		return super(QuestionSerializer, self).create(validated_data)

	def update(self, instance, validated_data):
		print ('questionSerializer update validated data', validated_data)
		return super(QuestionSerializer, self).update(instance, validated_data)

	class Meta:
		model = Question
		fields = ('question_id', 'section', 'maxpoints', 'intest', 'site', 'uxid')


class ScoreSerializer(serializers.ModelSerializer):
	id = serializers.CharField(required=False, allow_blank=True, max_length=100)
	question = QuestionSerializer()

	def validate(self, data):
		print('scoreserializer data', data)
		return data

	def create(self, validated_data):
		print ('scoreSerializer validated data', validated_data)
		return super(ScoreSerializer, self).create(validated_data)

	def update(self, instance, validated_data):
		print ('scoreSerializer update validated data', validated_data)
		return super(ScoreSerializer, self).update(instance, validated_data)

	class Meta:
		model = Score
		fields = ('id', 'points', 'value', 'rawinput', 'state', 'question')

class UserSerializer(UserDetailsSerializer):
	university = serializers.CharField(source="profile.university", allow_blank=True)
	study = serializers.CharField(source="profile.study", allow_blank=True)

	class Meta:
		model = get_user_model()
		fields = UserDetailsSerializer.Meta.fields + ('university', 'study', )

	def update(self, instance, validated_data):
		profile_data = validated_data.pop('profile', {})
		university = profile_data.get('university')
		study = profile_data.get('study')

		instance = super(UserSerializer, self).update(instance, validated_data)

		# get and update user profile
		profile = instance.profile
		if profile_data:
			if university:
				profile.university = university
			if study:
				profile.study = study
			profile.save()
		return instance

class UserProfileSerializer(serializers.ModelSerializer):
	class Meta:
		model = CourseProfile
		fields = ('university', 'study', )

class UserXSerializer(serializers.ModelSerializer):
	university = serializers.CharField(source="profile.university", required=False)
	study = serializers.CharField(source="profile.study", required=False)
	email = serializers.EmailField(allow_blank=True, max_length=100, required=False)

	class Meta:
		model = get_user_model()
		fields = ('username', 'first_name', 'last_name', 'email', 'university', 'study', )

	def create(self, validated_data):
		profile_data = validated_data.pop('profile', None)
		user = super(UserXSerializer, self).create(validated_data)
		self.create_or_update_profile(user, profile_data)
		return user

	def update(self, instance, validated_data):
		profile_data = validated_data.pop('profile', None)
		self.create_or_update_profile(instance, profile_data)
		return super(UserXSerializer, self).update(instance, validated_data)

	def create_or_update_profile(self, user, profile_data):
		print('profile_data', profile_data)
		profile, created = CourseProfile.objects.get_or_create(user=user, defaults=profile_data)
		if not created and profile_data is not None:
			return super(UserXSerializer, self).update(profile, profile_data)

class JWTUserSerializer(JWTSerializer):
	"""
	Adaptation of JWTSerializer, with added user profile
	"""
	token = serializers.CharField(read_only=True)
	user = UserSerializer(required=False)

	def update(self, instance, validated_data):
		profile_data = validated_data.pop('profile', {})
		university = profile_data.get('university')
		study = profile_data.get('study')

		instance = super(UserSerializer, self).update(instance, validated_data)

		# get and update user profile
		profile = instance.profile
		if profile_data:
			if university:
				profile.university = university
			if study:
				profile.study = study
			profile.save()
		return instance

class TokenProfileSerializer(TokenSerializer):
	class Meta:
		model = TokenModel
		fields = ('key',)


class RegistrationSerializer(RegisterSerializer):
	email = serializers.EmailField(required=False, allow_blank=True)
	first_name = serializers.CharField(required=False, allow_blank=True)
	last_name = serializers.CharField(required=False, allow_blank=True)
	university = serializers.CharField(required=False, allow_blank=True)
	study = serializers.CharField(required=False, allow_blank=True)

	def get_cleaned_data(self):
		return {
			'first_name': self.validated_data.get('first_name', ''),
			'last_name': self.validated_data.get('last_name', ''),
			'username': self.validated_data.get('username', ''),
			'password1': self.validated_data.get('password1', ''),
			'email': self.validated_data.get('email', ''),
			'university': self.validated_data.get('university', ''),
			'study': self.validated_data.get('study', '')
		}

	def custom_signup(self, request, user):
		"""
		Define a custom signup function (called in RegisterSerializer.save())
		that adds profile data to registered user
		"""
		user_data = self.get_cleaned_data()

		#that was created on user create in the signal
		profile = user.profile

		#set new fields
		profile.study = user_data['study']
		profile.university = user_data['university']

		profile.save()

class StatisticsSerializer(serializers.ModelSerializer):

	site = SiteSerializer()

	class Meta:
		model = Statistics
		fields = ('site', 'points', 'millis')

class UserDataSerializer(serializers.ModelSerializer):
	scores = ScoreSerializer(many=True, required=False)
	statistics = StatisticsSerializer(many=True, required=False)

	def validate(self, data):
		print('userdataserializer data', data)
		return data

	def create(self, validated_data):
		"""
		Method is used with all POST requests. And automatically handles
		create and update depending on uxid and user
		"""
		print('userDataSerializer validated_data', validated_data)

		user = None
		request = self.context.get("request")
		if request and hasattr(request, "user"):
			user = request.user

		if 'statistics' in validated_data:
			for statistic in validated_data['statistics']:

				#TODO this and similar can also be done with a serializer
				statistic_site = statistic.get('site', None)

				site, created = Site.objects.get_or_create(
					site_id = statistic_site.get('site_id', ''),
				)

				statistic_obj, created = Statistics.objects.get_or_create(
					site = site,
					user = user
				)

				statistic_obj.points = statistic.get('points', 0)
				statistic_obj.millis = statistic.get('millis', 0)
				statistic_obj.save()

		# Create or update each page instance
		if 'scores' in validated_data:
			for score in validated_data['scores']:

				# first: get or create a questions object
				score_question = score.get('question', None)
				score_question_site = score_question.get('site', None)

				site, site_created = Site.objects.get_or_create(
					site_id = score_question_site.get('site_id', ''),
				)

				question, q_created = Question.objects.get_or_create(
					question_id = score_question.get('question_id', ''),
					site = site
				)
				question.uxid = score_question.get('uxid', None)
				question.section = score_question.get('section', 0)
				question.maxpoints = score_question.get('maxpoints', 0)
				#question.type = score_question.get('type', None)
				question.intest = score_question.get('intest', False)
				question.save()

				# second: get or create the score obj defined by question and user, which

				the_score, score_created = Score.objects.get_or_create(
					question=question,
					user=user
				)

				# third: set the other fields on the object and save
				the_score.points = score.get('points', the_score.points)
				the_score.value = score.get('value', the_score.value)
				the_score.rawinput = score.get('rawinput', the_score.rawinput)
				the_score.state = score.get('state', the_score.state)

				the_score.save()

		return user

	class Meta:
		model = get_user_model()
		fields = ('email', 'scores', 'statistics')


def jwt_response_payload_handler(token, user=None, request=None):
	return {
		'token': token,
		'user': UserSerializer(user, context={'request': request}).data
	}
