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
    }
  ],
  //timeout in seconds
  timeout: 1,
  //watchdog interval in minutes
  interval: 5/60
};
