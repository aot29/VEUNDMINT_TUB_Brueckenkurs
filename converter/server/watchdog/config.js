//config file for watchdog
module.exports = {
  services: [
    {
      name: 'feedback',
      url: 'http://localhost/mint/converter/server/dbtest/feedback.php',
      ping: true,
      requests: [
        {name: '1', method: 'POST', data: {feedback: 'watchdog'},
          test: function (response) {
            return (new RegExp('^success')).test(response);}
        }
      ]
    },
    {
      name: 'userdata',
      url: 'http://localhost/mint/converter/server/dbtest/userdata.php',
      ping: false,
      requests: [
        {name: 'check_user', method: 'GET', data: {action: 'check_user'},
          test: function (response) {
            return JSON.parse(response).status === true;
          }}
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
      url: 'http://i-hope-this-domain-doesnt-exist.org',
      requests: []
    },
    {
      name: 'timeout',
      ping: false,
      url: 'http://localhost/sleep.php',
      requests: [
        {name: '1', method: 'GET', data: {},
          test: function (response) {
            return response === 'Hallo Welt!';
          }
        }
      ]
    }
  ],
  //timeout in seconds
  timeout: 3,
  //watchdog interval in minutes
  interval: 5/60
};
