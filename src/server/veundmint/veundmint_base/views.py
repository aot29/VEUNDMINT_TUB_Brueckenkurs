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
			print('QUESTIONS', questions)
			for question in questions:
				resp[site.site_id][question.question_id] = {}
				question_scores = Score.objects.filter(user=user, question=question)
				print('QUESTION_SCORES', question_scores)
				for score in question_scores:
					resp[site.site_id][question.question_id] = ScoreSerializer(score).data
			resp[site.site_id]['millis'] = 0
			resp[site.site_id]['totalScore'] = site.totalScore
			resp[site.site_id]['maxScore'] = site.maxScore
		return Response(resp)


class UserViewSet(viewsets.ModelViewSet):

	serializer_class = UserDataSerializer

	def get_queryset(self):
		user = self.request.user
		return get_user_model().objects.filter(pk=user.pk)

	def create(self, request):
		stats = request.data.get('stats', None)

		if stats is not None:
			transformed_scores = []
			for site in stats:
				for key in stats[site]:
					print(key)
					if key != 'millis' and key != 'points':
						print('key is question')
						score = stats[site][key]

						print('score is :\n', score)
						print('\n')

						transformed_score = {}
						transformed_score['rawinput'] = score.get('rawinput', '')
						transformed_score['points'] = score.get('points', 0)
						transformed_score['value'] = score.get('value', 0)
						transformed_score['state'] = score.get('state', 0)
						print(transformed_score)

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
						print ('x-x-x-x\n', transformed_score)
						transformed_scores.append(transformed_score)

						request.data['scores'] = transformed_scores

		#here we transform the posted data
		# scores = request.data.get('scores', None)
		# print('userviewset scores', scores)
		# if scores is not None:
		# 	transformed_scores = []
		# 	for score in scores:
		# 		transformed_score = {}
		# 		transformed_score['rawinput'] = score.get('rawinput', '')
		# 		transformed_score['points'] = score.get('points', 0)
		# 		transformed_score['value'] = score.get('value', 0)
		# 		transformed_score['state'] = score.get('state', 0)
		#
		# 		question={}
		# 		question['question_id'] = score.get('id', '')
		# 		question['siteuxid'] = score.get('siteuxid', '')
		# 		question['section'] = score.get('section', 0)
		# 		question['maxpoints'] = score.get('maxpoints', 0)
		# 		question['intest'] = score.get('intest', False)
		# 		question['type'] = score.get('type', None)
		#
		# 		transformed_score['question'] = question
		#
		# 		transformed_scores.append(transformed_score)
		#
		# 	print ('transformed_scores', transformed_scores)
		# 	request.data['scores'] = transformed_scores

		return super(UserViewSet, self).create(request)

	def list(self, request, *args, **kwargs):
		queryset = self.get_queryset()

		serializer = UserDataSerializer(self.request.user)
		data = serializer.data
		print(data)
		#data['totalScore'] = sum([score['points'] for score in data['scores']])
		# TODO this will be for the new data Structure with scores not array but obj
		# newscores = {}
		# for score in data['scores']:
		#     newscores[score['id']] = score
		# data['scores'] = newscores
		# #result = {'totalScore': sum([score['points'] for score in data.scores]), 'data':data}
		return Response(data)

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
