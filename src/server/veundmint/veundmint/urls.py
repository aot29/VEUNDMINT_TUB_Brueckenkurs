"""veundmint URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.10/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.conf.urls import url, include
    2. Add a URL to urlpatterns:  url(r'^blog/', include('blog.urls'))
"""
from django.conf.urls import include, url
from django.conf import settings
from django.conf.urls import include, url
from django.contrib import admin
from django.views.generic import TemplateView

from rest_framework import routers
from rest_framework_jwt.views import obtain_jwt_token
from rest_auth.registration.views import VerifyEmailView

from veundmint_base.models import WebsiteAction
from veundmint_base.views import WebsiteActionViewSet, UserViewSet, ScoreViewSet,\
ProfileViewSet, CheckUsernameView, DataTimestampView, UserFeedbackViewSet, NewUserDataViewSet


router = routers.DefaultRouter()
router.register(r'server-action', WebsiteActionViewSet)
router.register(r'score', ScoreViewSet, base_name='scores')
router.register(r'user-data', UserViewSet, base_name='user-data')
router.register(r'user-feedback', UserFeedbackViewSet)
#router.register(r'new-user-data', NewUserDataViewSet, base_name='new-user-data')

urlpatterns = [
    #url(r'^', include('veundmint_base.urls')),
    url(r'^', include(router.urls)),
    url(r'^admin/', admin.site.urls),
    url(r'^api-auth/', include('rest_framework.urls', namespace='rest_framework')),
    url(r'^rest-auth/', include('rest_auth.urls')),
    url(r'^rest-auth/registration/', include('rest_auth.registration.urls')),
    url(r'^api-token-auth/', obtain_jwt_token),
    url(r'^checkusername/', CheckUsernameView.as_view()),
    url(r'^user-data-timestamp/', DataTimestampView.as_view()),
    url(r'^new-user-data/', NewUserDataViewSet.as_view())
]

if settings.DEBUG:
    import debug_toolbar
    urlpatterns += [
        url(r'^__debug__/', include(debug_toolbar.urls)),
    ]
