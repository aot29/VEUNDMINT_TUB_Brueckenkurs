from rest_framework import serializers
from django.contrib.auth import get_user_model
from veundmint_base.models import WebsiteAction, Score, UserFeedback

# Serializers define the API representation.
class WebsiteActionSerializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = WebsiteAction
        fields = ('action_id', 'created_at', 'browser_type', 'ip_address')

class UserFeedbackSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserFeedback
        fields = ('rawfeedback', )

class ScoreSerializer(serializers.ModelSerializer):
    id = serializers.CharField(required=False, allow_blank=True, max_length=100, source='q_id')
    class Meta:
        model = Score
        fields = ('id', 'siteuxid', 'section', 'maxpoints', 'intest', 'uxid', 'points', 'value', 'rawinput', 'state')

class UserDataSerializer(serializers.ModelSerializer):
    scores = ScoreSerializer(many=True, required=False)

    def create(self, validated_data):
        """
        Method is used with all POST requests. And automatically handles
        create and update depending on uxid and user
        """
        user = None
        request = self.context.get("request")
        if request and hasattr(request, "user"):
            user = request.user

        # Create or update each page instance
        if 'scores' in validated_data:
            for score in validated_data['scores']:

                # first get or create the score obj defined by id and user, which
                # should be unique together - q_id is rendered as id in
                # ~ScoreSerializer
                #
                print (score)
                the_score, created = Score.objects.get_or_create(
                    q_id=score['q_id'],
                    user=user
                )

                # then set the other fields on the object and save
                # validated_data.get('baumart', instance.baumart)
                the_score.points = score.get('points', the_score.points)
                the_score.siteuxid = score.get('siteuxid', the_score.siteuxid)
                the_score.section = score.get('section', the_score.section)
                the_score.maxpoints = score.get('maxpoints', the_score.maxpoints)
                the_score.intest = score.get('intest', the_score.intest)
                the_score.value = score.get('value', the_score.value)
                the_score.rawinput = score.get('rawinput', the_score.rawinput)
                the_score.state = score.get('state', the_score.state)
                the_score.uxid = score.get('uxid', the_score.uxid)

                print ('created: %s, updated %s, : %s' % (created, not created, ScoreSerializer(the_score).data))
                the_score.save()

        return user

    class Meta:
        model = get_user_model()
        fields = ('email', 'scores')
