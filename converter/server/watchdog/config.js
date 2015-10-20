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
      url: 'http://mintlx3.scc.kit.edu/dbtest/userdata.php?session_id=WATCHDOG',
      ping: true,
      notify: true,
      requests: [
        /*
         * This logs in to the user database as user "WATCHDOG" with password "WATCHDOG" and
         * checks if it can write data to the database.
         */
        {
          name: 'check_user', method: 'GET', data: {action: 'check_user', username: "WATCHDOG"},
          test: function (response, reqObject, log) {
            try {
              var responseObject = JSON.parse(response);
            } catch (exception) {
              return false;
            }

            if (responseObject.user_exists === false) {
              console.log("WATCHDOG user doesn't exist in the database, you have to create (with password WATCHDOG)."); //TODO this doesn't get logged to the log or email
              return false;
            }
            return responseObject.status === true;
          },
          threshold: 1000
        },
        {
          name: 'login', method: 'POST', data: {action: 'login', username: "WATCHDOG", password: "WATCHDOG"},
          test: function (response, reqObject, log) {
            try {
              var responseObject = JSON.parse(response);
            } catch (exception) {
              return false;
            }

            return responseObject.status === true;
          },
          threshold: 1000
        },
        {
          name: 'write_data', method: 'POST', data: {action: 'write_data', username: "WATCHDOG", data: "WATCHDOG test data"},
          test: function (response, reqObject, log) {
            try {
              var responseObject = JSON.parse(response);
            } catch (exception) {
              return false;
            }

            return responseObject.status === true;
          },
          threshold: 1000
        }
      ]
    },
    {
      name: 'course',
      ping: true,
      notify: true,
      url: 'http://mintlx3.scc.kit.edu/veundmintkurs/mpl/3.1.html',
      requests: [
        {
          name: '1', method: 'GET', data: {}, test: function (response, reqObject) {
            return reqObject.statusCode === 200;
          },
          threshold: 1000
        }
      ]
    },
    {
      name: 'mintlx1_ilias_login',
      ping: true,
      notify: true,
      url: 'http://mintlx1.scc.kit.edu/ilias/login.php',
      requests: [
        {
          name: '1', method: 'GET', data: {}, test: function (response, reqObject) {
            return reqObject.statusCode === 200;
          },
          threshold: 1000
        }
      ]
    },
    {
      name: 'test_mintlx3_online.html',
      ping: true,
      notify: true,
      url: 'http://mintlx3.scc.kit.edu/test_mintlx3_online.html',
      requests: [
        {
          name: '1', method: 'GET', data: {}, test: function (response, reqObject) {
            return reqObject.statusCode === 200;
          },
          threshold: 1000
        }
      ]
    } ],
  diskusage: [
    {path: './', notify_percentage: 80}
  ],
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
