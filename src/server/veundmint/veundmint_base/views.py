import random, string, json

from django.utils import timezone
from django.shortcuts import render
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.contrib.auth import get_user_model
from django.core.exceptions import ObjectDoesNotExist
from django.conf import settings

from rest_framework import viewsets, permissions, authentication, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.generics import CreateAPIView, RetrieveUpdateAPIView, GenericAPIView
from rest_framework.mixins import CreateModelMixin, RetrieveModelMixin

from rest_auth.registration.views import RegisterView
from rest_auth.utils import jwt_encode

from allauth.account import app_settings as allauth_settings
from allauth.account.utils import complete_signup

from veundmint_base.serializers import UserDataSerializer, WebsiteActionSerializer, \
ScoreSerializer, UserFeedbackSerializer, JWTUserSerializer, UserSerializer, UserXSerializer, \
JWTUserSerializer, NewUserDataSerializer, SiteSerializer
from veundmint_base.models import WebsiteAction, Score, UserFeedback, Site, Question


# ViewSets define the view behavior.
class WebsiteActionViewSet(viewsets.ModelViewSet):
    queryset = WebsiteAction.objects.all()
    serializer_class = WebsiteActionSerializer
    permission_classes = (permissions.AllowAny,)

class UserFeedbackViewSet(viewsets.ModelViewSet):
    queryset = UserFeedback.objects.all()
    serializer_class = UserFeedbackSerializer
    permission_classes = (permissions.AllowAny,)

class NewUserDataViewSet(APIView):
	"""
	A simple ViewSet for listing or retrieving users.
	"""
	def get(self, request, format=None):
		user = self.request.user
		scores = Score.objects.filter(pk=user.pk)
		sites = Site.objects.all()
		resp = {}
		for site in sites:
			resp[site.site_id] = {}
			questions = site.questions.all()
			for question in questions:
				resp[site.site_id][question.question_id] = {}
				question_scores = Score.objects.filter(user=user, question=question)
				for score in question_scores:
					resp[site.site_id][question.question_id] = ScoreSerializer(score).data
			resp[site.site_id]['millis'] = 0
			resp[site.site_id]['totalScore'] = site.totalScore
			resp[site.site_id]['maxScore'] = site.maxScore
		return Response(resp)


class UserViewSet(viewsets.ModelViewSet):
	"""
	This is the main ViewSet that is responsible for serializing received user
	data to django's database architecture. Pay attention to the create and list
	methods below, as they transform data because the client has a different
	data structure than the django orm and thus needs some transformation.
	"""

	serializer_class = UserDataSerializer

	def get_queryset(self):
		user = self.request.user
		return get_user_model().objects.filter(pk=user.pk)

	def create(self, request):
		"""
		This method handles all POST requests to the endpoint defined in urls.py.
		It will transform the json object received from a js client to a format
		that is readable by the involved serializers for statistics, scores,
		questions, sites. That means that the simplified js json structure is
		rebuilt to match object relations defined in django models.
		"""
		stats = request.data.get('stats', None)

		# The stats object is all we need and get
		if stats is not None:
			transformed_scores = []
			transformed_statistics = []

			for site in stats:

				#handle passed statistics
				site_statistic = {}
				site_statistic['millis'] = stats[site].get('millis', 0)
				site_statistic['points'] = stats[site].get('points', 0)
				site_statistic['site'] = {'site_id': site}
				transformed_statistics.append(site_statistic)

				#for all keys that are in stats (which can either be keys to
				#sites or points or millis)
				for key in stats[site]:
					if key != 'millis' and key != 'points':
						score = stats[site][key]

						transformed_score = {}
						transformed_score['rawinput'] = score.get('rawinput', '')
						transformed_score['points'] = score.get('points', 0)
						transformed_score['value'] = score.get('value', 0)
						transformed_score['state'] = score.get('state', 0)

						site_obj = {}
						site_obj['site_id'] = score.get('siteuxid', '')

						question={}
						question['question_id'] = score.get('id', '')
						question['section'] = score.get('section', 0)
						question['maxpoints'] = score.get('maxpoints', 0)
						question['intest'] = score.get('intest', False)
						question['type'] = score.get('type', None)
						question['site'] = site_obj

						transformed_score['question'] = question
						transformed_scores.append(transformed_score)

			request.data['scores'] = transformed_scores
			request.data['statistics'] = transformed_statistics

		return super(UserViewSet, self).create(request)

	def list(self, request, *args, **kwargs):
		queryset = self.get_queryset()

		serializer = UserDataSerializer(self.request.user)
		data = serializer.data
		statistics = data.get('statistics', None)
		scores = data.get('scores', None)

		new_data = {}
		stats = {}
		full_site_obj = {}

		for score in scores:
			print(score)
			site_scores = {}
			score_site_id = score['question']['site']['site_id']
			score_question_id = score['question']['question_id']

			if score_site_id not in stats:
				stats[score_site_id] = {}

			if score_question_id not in stats[score_site_id]:
				stats[score_site_id][score_question_id] = {
					'id' : score.get('id', None),
					'points' : score.get('points', 0),
					#TODO 'uxid': score.get
					'siteuxid' : score['question']['site']['site_id'],
					'rawinput': score.get('rawinput', ''),
					'maxpoints': score['question']['maxpoints'],
					'value': score.get('value', 0),
					'section': score.get('section', 0),
					'intest': score['question']['intest'],
					'type': score.get('type', None)
				}

		for site in statistics:
			site_id = site['site']['site_id']

			if site_id not in stats:
				stats[site_id] = {}

			stats[site_id]['millis'] = site.get('millis', 0)
			stats[site_id]['points'] = site.get('points', 0)

		new_data['stats'] = stats

		#data['totalScore'] = sum([score['points'] for score in data['scores']])
		# TODO this will be for the new data Structure with scores not array but obj
		# newscores = {}
		# for score in data['scores']:
		#     newscores[score['id']] = score
		# data['scores'] = newscores
		# #result = {'totalScore': sum([score['points'] for score in data.scores]), 'data':data}
		return Response(new_data)

class ProfileViewSet(viewsets.ViewSet):

    serializer_class = UserDataSerializer

    def get_queryset(self):
        user = self.request.user
        return get_user_model().objects.filter(pk=user.pk)


class ScoreViewSet(viewsets.ModelViewSet):

    serializer_class = ScoreSerializer
    permission_classes = (permissions.IsAuthenticated,)

    def get_queryset(self):
        """
        This view should return a list of all the scores
        for the currently authenticated user.
        """
        user = self.request.user
        return Score.objects.filter(user=user)

class CheckUsernameView(APIView):
	"""
	View to check if a username is available
	Consumes a `GET` parameter with key `username`
	"""
	permission_classes = (permissions.AllowAny,)

	def get(self, request, format=None):
		"""
		Return {'username_available' : true / false} or if no username was provided an error
		"""
		usernames = [user.username for user in get_user_model().objects.all()]
		username = self.request.query_params.get('username', None)
		if username is None:
			response = Response({'error':'provide a username'}, status=status.HTTP_400_BAD_REQUEST)
		else:
			available = not get_user_model().objects.filter(username=username).exists()
			response = Response({'username_available': available})

		return response

class DataTimestampView(APIView):
    """
    View to get the data timestamp of the saved user data
    """

    permission_classes = (permissions.IsAuthenticated, )

    def get(self, request, format=None):
        """
        Return the timestamp of the latest data as a number
        """
        user = self.request.user
        try:
            latestUserScore = Score.objects.filter(user=user).latest('updated_at').updated_at
            latestUserScoreTimestamp = timezone.make_naive(latestUserScore).timestamp() * 1000 - 2000
            #we return a slightly throttled timestamp (2 sec) in order to to privilege localstorage
        except ObjectDoesNotExist:
            latestUserScoreTimestamp = -1
        return Response(int(latestUserScoreTimestamp));
