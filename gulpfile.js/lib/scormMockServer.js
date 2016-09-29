var nock = require('nock');

nock('https://scorm.mock')
	.get('/users/22').reply(200, {
		username: 'davidwalshblog',
		firstname: 'David'
	});

nock('https://scorm.mock')
	.get('/content/homepage')
	.reply(200, 'This is the HTML for the homepage');

nock('scorm.mock')
	.get('/content/page-no-exist')
	.reply(404, 'This page could not be found');