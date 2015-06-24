//config file for watchdog
module.exports = {
  services: [
    {
      name: 'feedback',
      url: 'http://localhost/mint/converter/server/dbtest/feedback.php',
      requests: [
        {name: '1', method: 'POST', data: {feedback: 'watchdog'}, regex: new RegExp('^success')}
      ]
    },
    {
      name: 'userdata',
      url: 'http://localhost/mint/converter/server/dbtest/userdata.php',
      requests: []
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
