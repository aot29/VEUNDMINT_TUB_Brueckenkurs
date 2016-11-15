import random, string

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
JWTUserSerializer
from veundmint_base.models import WebsiteAction, Score, UserFeedback


# ViewSets define the view behavior.
class WebsiteActionViewSet(viewsets.ModelViewSet):
    queryset = WebsiteAction.objects.all()
    serializer_class = WebsiteActionSerializer
    permission_classes = (permissions.AllowAny,)

class UserFeedbackViewSet(viewsets.ModelViewSet):
    queryset = UserFeedback.objects.all()
    serializer_class = UserFeedbackSerializer
    permission_classes = (permissions.AllowAny,)

class UserViewSet(viewsets.ModelViewSet):

    serializer_class = UserDataSerializer

    def get_queryset(self):
        user = self.request.user
        return get_user_model().objects.filter(pk=user.pk)

    def list(self, request, *args, **kwargs):
        queryset = self.get_queryset()

        serializer = UserDataSerializer(self.request.user)
        data = serializer.data
        data['totalScore'] = sum([score['points'] for score in data['scores']])
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
