//config file for watchdog
module.exports = {
  services: [
    {
      name: 'feedback',
      url: 'http://localhost/mint/converter/server/dbtest/feedback.php',
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
      requests: [
        {name: 'check_user', method: 'GET', data: {action: 'check_user'},
          test: function (response) {
            console.log(response);
            return JSON.parse(response).status === true;
          }}
      ]
    },
    {
      name: 'course',
      url: 'http://localhost/mint/testhtml',
      requests: []
    }
  ],
  //timeout in seconds
  timeout: 10,
  //watchdog interval in minutes
  interval: 5
};
