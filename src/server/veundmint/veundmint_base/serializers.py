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

class ScoreListSerializer(serializers.ListSerializer):
	
	def to_internal_value(self, data):
		"""
		List of dicts of native values <- List of dicts of primitive datatypes.
		"""
		print('to_internal_value data', data)
		
		transformed_data = []
		
				#return {
			#'intest': data.question.intest, 
			#'maxpoints': data.question.maxpoints, 
			#'siteuxid': data.question.siteuxid,  
			#'section': data.question.section, 
			#'type': data.question.type,
			#'rawinput': data.rawinput, 
			#'id': data.id,
			#'points': data.points, 
			#'value': data.value, 
			#'state': data.state
			#}
		
		for q_key, score in data.items():
			print('SCORE IS SCORE IS', score)
			transformed_data.append({
				'question': {
					'question_id': q_key,
					'intest': score.get('intest', False),
					'siteuxid': score.get('siteuxid', None),
					'section': score.get('section', None),
					'type': score.get('type', None),
					'maxpoints': score.get('maxpoints',0)
				},
				'id': score.get('id', None),
				'points': score.get('points', 0),
				'value': score.get('value', None),
				'state': score.get('state', None)
			})
		return super(ScoreListSerializer, self).to_internal_value(transformed_data)

	def to_representation(self, data):
		"""
		List of object instances -> List of dicts of primitive datatypes.
		"""
		# Dealing with nested relationships, data can be a Manager,
		# so, first get a queryset from the Manager if needed
		iterable = data.all() if isinstance(data, models.Manager) else data

		return {
			item.question.question_id : self.child.to_representation(item) for item in iterable
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
		
class QuestionSerializer(serializers.ModelSerializer):
	
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
		fields = ('question_id', 'section', 'maxpoints', 'intest', 'type')
		

class ScoreSerializer(serializers.ModelSerializer):
	id = serializers.CharField(required=False, allow_blank=True, max_length=100)
	maxpoints = serializers.IntegerField(source="question.maxpoints")
	
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
		fields = ('id', 'points', 'value', 'rawinput', 'state', 'maxpoints')

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
		print ('JWT update')
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
		
class SiteSerializer(serializers.ModelSerializer):
	id = serializers.CharField(required=False, allow_blank=True, max_length=100)
	
	class Meta:
		model = Site
		list_serializer_class = SiteListSerializer

class StatisticsSerializer(serializers.ModelSerializer):
	
	site = SiteSerializer()
	
	class Meta:
		model = Statistics
		fields = ('site', )

class NewScoreSerializer(serializers.ModelSerializer):
	id = serializers.CharField(required=False, allow_blank=True, max_length=100)
	question = QuestionSerializer(required=False)
	
	def to_internal_value(self, data):
		print('to_internal_value', data)
		question = data.get('question')
		points = data.get('points')

		# Perform the data validation.
		#if not score:
			#raise ValidationError({
				#'score': 'This field is required.'
			#})

		# Return the validated values. This will be available as
		# the `.validated_data` property.
		return {
			'points': int(points),
			'question': question
		}
	
	def to_representation(self, data):
		"""
		We override the to_representation method to flatten the object
		"""
		print(data.__dict__)
		
		return {
			'intest': data.question.intest, 
			'maxpoints': data.question.maxpoints, 
			'section': data.question.section, 
			'type': data.question.type,
			'rawinput': data.rawinput, 
			'id': data.id,
			'points': data.points, 
			'value': data.value, 
			'state': data.state
			}

	class Meta:
		model = Score
		list_serializer_class = ScoreListSerializer
		fields = ('id', 'question', 'points', 'rawinput', 'state')


class NewUserDataSerializer(serializers.ModelSerializer):
	
	statistics = StatisticsSerializer(many=True)
	
	#scores = NewScoreSerializer(many=True)
	
	#def create(self, validated_data):
		#"""
		#Method is used with all POST requests. And automatically handles
		#create and update depending on uxid and user
		#"""
		#print('userDataSerializer validated_data', validated_data)
		
		#user = None
		#request = self.context.get("request")
		#if request and hasattr(request, "user"):
			#user = request.user

		## Create or update each page instance
		#if 'scores' in validated_data:
			#for score in validated_data['scores']:

				## first: get or create a questions object
				#score_question = score.get('question', None)
				
				#question, created = Question.objects.get_or_create(
					#question_id = score_question.get('question_id', ''),
					#siteuxid = score_question.get('siteuxid', ''),
					#section = score_question.get('section', 0),
					#maxpoints = score_question.get('maxpoints', 0),
					#intest = score_question.get('intest', False),
					#type = score_question.get('type', None)
				#)


				## second: get or create the score obj defined by question and user, which

				#the_score, created = Score.objects.get_or_create(
					#question=question,
					#user=user
				#)

				## third: set the other fields on the object and save
				#the_score.points = score.get('points', the_score.points)
				#the_score.value = score.get('value', the_score.value)
				#the_score.rawinput = score.get('rawinput', the_score.rawinput)
				#the_score.state = score.get('state', the_score.state)

				#print ('created: %s, updated %s, : %s' % (created, not created, ScoreSerializer(the_score).data))
				#the_score.save()

		#return user
	
	class Meta:
		model = get_user_model()
		fields = ('email', 'scores', 'statistics')

class UserDataSerializer(serializers.ModelSerializer):
	scores = ScoreSerializer(many=True, required=False)
	
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

		# Create or update each page instance
		if 'scores' in validated_data:
			for score in validated_data['scores']:

				# first: get or create a questions object
				score_question = score.get('question', None)
				
				question, created = Question.objects.get_or_create(
					question_id = score_question.get('question_id', ''),
					siteuxid = score_question.get('siteuxid', ''),
					section = score_question.get('section', 0),
					maxpoints = score_question.get('maxpoints', 0),
					intest = score_question.get('intest', False),
					type = score_question.get('type', None)
				)


				# second: get or create the score obj defined by question and user, which

				the_score, created = Score.objects.get_or_create(
					question=question,
					user=user
				)

				# third: set the other fields on the object and save
				the_score.points = score.get('points', the_score.points)
				the_score.value = score.get('value', the_score.value)
				the_score.rawinput = score.get('rawinput', the_score.rawinput)
				the_score.state = score.get('state', the_score.state)

				print ('created: %s, updated %s, : %s' % (created, not created, ScoreSerializer(the_score).data))
				the_score.save()

		return user

	class Meta:
		model = get_user_model()
		fields = ('email', 'scores')


def jwt_response_payload_handler(token, user=None, request=None):
	print('I AM RESPONSING')
	return {
		'token': token,
		'user': UserSerializer(user, context={'request': request}).data
	}
