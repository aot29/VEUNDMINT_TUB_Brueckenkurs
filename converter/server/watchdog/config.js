//config file for watchdog
module.exports = {
  services: [
    {
      name: 'feedback',
      url: 'http://localhost/mint/converter/server/dbtest/feedback.php',
      ping: true,
      notify: true,
      requests: [
        {name: '1', method: 'POST', data: {feedback: 'watchdog'},
          test: function (response, reqObject) {
            return (new RegExp('^success')).test(response);
          },
          //threshold in ms (if threshold is reached, there will be a notification)
          threshold: 1000
        }
      ]
    },
    {
      name: 'userdata',
      url: 'http://localhost/mint/converter/server/dbtest/userdata.php',
      ping: false,
      notify: true,
      requests: [
        {name: 'check_user', method: 'GET', data: {action: 'check_user'},
          test: function (response, reqObject) {
            return JSON.parse(response).status === true;
          },
          threshold: 1000
        }
      ]
    },
    {
      name: 'course',
      ping: true,
      url: 'http://localhost/mint/testhtml',
      requests: []
    },
    {
      name: 'unknown_host',
      ping: true,
      notify: true,
      url: 'http://i-hope-this-domain-doesnt-exist.org',
      requests: []
    },
    {
      name: 'timeout',
      ping: false,
      notify: true,
      url: 'http://localhost/sleep.php',
      requests: [
        {name: '1', method: 'GET', data: {},
          test: function (response) {
            return response === 'Hallo Welt!';
          },
          threshold: 1000
        }
      ]
    }
  ],
  //timeout in seconds
  timeout: 3,
  //watchdog interval in minutes
  interval: 5/60,
  email: {
    from: "Foo Bar <foo@bar.baz",
    to: "someone@somewhere.tld",
    subject: "Watchdog"
  }
};
