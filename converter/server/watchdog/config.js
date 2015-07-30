//config file for watchdog
module.exports = {
  services: [
    {
      name: 'feedback',
      url: 'http://mintlx3.scc.kit.edu/dbtest/feedback.php',
      ping: true,
      notify: true,
      requests: [
        {
          name: '1', method: 'POST', data: {feedback: 'WATCHDOG'},
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
      url: 'http://mintlx3.scc.kit.edu/dbtest/userdata.php',
      ping: true,
      notify: true,
      requests: [
        {
          name: 'check_user', method: 'GET', data: {action: 'check_user'},
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
      url: 'http://mintlx3.scc.kit.edu/veundmint_kit/mpl/3.1.html',
      requests: [
        {
          name: '1', method: 'GET', data: {}, test: function (response, reqObject) {
            return true;
          },
          threshold: 1000
        }
      ]
    },
    {
      name: 'mintlx1_ilias_login',
      ping: true,
      url: 'http://mintlx1.scc.kit.edu/ilias/login.php',
      requests: [
        {
          name: '1', method: 'GET', data: {}, test: function (response, reqObject) {
            return true;
          },
          threshold: 1000
        }
      ]
    },
    {
      name: 'tester_dh',
      ping: true,
      url: 'http://mintlx3.scc.kit.edu/test_mintlx3_alive.html',
      requests: [
        {
          name: '1', method: 'GET', data: {}, test: function (response, reqObject) {
            return true;
          },
          threshold: 1000
        }
      ]
    } ],
  logfile: '/opt/watchdog/log',
  errorlog: '/opt/watchdog/errorlog',
  //timeout in seconds
  timeout: 20,
  //watchdog interval in minutes
  interval: 5,
  email: {
    from: "VE&MINT INFO <info@ve-und-mint.de>",
    to: "info@ve-und-mint.de", // sender and recipient are the same on purpose
    subject: "VE&MINT watchdog alert"
  },
  mailoptions: {
    port: 587, // used by TLS connection
    host: "smtp.something.org",
    secure: true,
    auth: { user: "USERNAME", pass: "PASSWORD" },
    ignoreTLS: false // true -> port should be 25
  }
};
