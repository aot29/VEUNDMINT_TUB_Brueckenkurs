from rest_framework import serializers
from django.contrib.auth import get_user_model
from veundmint_base.models import WebsiteAction, Question, Score, UserFeedback, CourseProfile
from rest_auth.registration.serializers import RegisterSerializer
from rest_auth.serializers import UserDetailsSerializer, JWTSerializer, TokenSerializer
from rest_auth.models import TokenModel

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
		print('scoreserializer data', data)
		return data

	class Meta:
		model = Question
		fields = ('question_id', 'siteuxid', 'section', 'maxpoints', 'intest', 'type')

class ScoreSerializer(serializers.ModelSerializer):
	id = serializers.CharField(required=False, allow_blank=True, max_length=100)
	#question = QuestionSerializer(required=False)
	
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
		fields = ('id', 'question', 'points', 'value', 'rawinput', 'state')

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
				print(score)

				# first: get or create a questions object
				question, created = Question.objects.get_or_create(
					question_id = score.get('q_id', ''),
					siteuxid = score.get('siteuxid', ''),
					section = score.get('section', 0),
					maxpoints = score.get('maxpoints', 0),
					intest = score.get('intest', False)
				)
				print(question)

				# second: get or create the score obj defined by question and user, which
				# should be unique together - q_id is rendered as id in
				# ~ScoreSerializer

				the_score, created = Score.objects.get_or_create(
					question=question,
					user=user
				)

				print(question)

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
