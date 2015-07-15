Watchdog
========

About
-----
Watchdog is a program to watch web services for their availability and automatically sending an Email if a services responds to slowly or doesn't even respond at all.

Usage
-----
Before you run this, make sure you have *nodejs* and *npm* installed. Then install the dependencies with `npm install`. If you want to send email notifications, you need to also have *sendmail* installed.

You can run it directly with `./watchdog.js` or via `node watchdog.js` (might be `nodejs watchdog.js` on some GNU/Linux distributions).

If you want to save the output to a log file, use shell redirection: `./watchdog.js 1>> logfile`

Installation as a service (with systemd)
----------------------------------------

As root, do the following:
```
# mkdir /opt/watchdog
# groupadd watchdog
# useradd -d /opt/watchdog -g watchdog watchdog
# cp LICENSE.TXT README.md watchdog.service package.json config.js watchdog.js /opt/watchdog/
# chown -R watchdog:watchdog /opt/watchdog
# su - watchdog
$ cd /opt/watchdog
$ npm install
$ exit
```

**Note:** The following only applies when using a distribution that uses systemd as it's init system (Debian since 8 Jessie, Ubuntu since 15.04 Vivid Vervet, CentOS since 7, Fedora since 14, Archlinux etc.). If you don't have systemd available, you'll be on your own with writing an init script, I definitely won't do it.

Now make sure the configuration in `/opt/watchdog/config.js` is as desired. You also might have to change the systemd service file `watchdog.service` (eg. `/usr/bin/nodejs` -> '/usr/bin/node' or change the name of the user and group). Then install, enable and start the service (as root):
```
# cp watchdog.service /etc/systemd/system/
# systemctl enable watchdog.service
# systemctl status watchdog.service
```

You can make sure that watchdog is actually running with `systemctl status watchdog.service`.

Watchdog will now automatically start at every boot.

Features
--------
Watchdog performs checks on the availability of services in regular intervals. It can check the following:
* ping the host
* make an HTTP request (GET, POST etc.) and check the validity of the response
* send email notifications via sendmail
* check if a request takes too long

Output
------
Watchdog checks the services specified in `config.js` in regular intervals and prints the result to stdout. The result ist a JSON-String of the following form (this examples uses JavaScript syntax to make it more readable, but the output of Watchdog is real JSON):

```js
{
  timestamp: 1436369255.77, //Unix timestamp
  services: {
    service_one: {
      ping: true, //boolean value if ping is enabled in config.js
      requests: {
        request_one: {
          response: true, //boolean value
          success: true, //boolean value based on the result of a callback defined in config.js
          time: 10, //request time in ms. Not entirely accurate, might be incorrect by a few ms.
          threshold_reached: true, //boolean value if a threshold is set in config.js
        },
        request_two: {
          response: false,
          success: false
        }
      }
    },
    service_two: {
      ping: true
    },
    another_service: {
      ping: false
    }
  }
}
```

**Note:** Every line of output is a JSON-String of itself, not the entire output.

Configuration
-------------
Watchdog uses the concept of services. Each service has one URL. You can do the following with a service:
* ping the host
* send HTTP requests to the URL and manually check the result (via a javascript callback)
* set a threshold for the response time to send a notification email

Here is an example configuration that should explain how this works:
```js
//config file for watchdog. Note that this is a javascript file that gets loaded as a module by
//watchdog, so you can write any javascript you want in this file.
module.exports = {
  services: [ //use this array to define the services you want to watch
    {
      name: 'service_one',
      url: 'http://somewhere.else/service_one.php',
      ping: true,
      notify: true,
      requests: [ //use this array to define the requests you want to make to this service
                  //if you don't want to send any requests, use an empty array
        {
          name: 'get-request',
          method: 'GET',
          data: {id: '1234'},
          test: function (response, reqObj) { //callback to determine if the request was successful
            if (response = 'Hello world!') {
              return true;
            }
            return false;
          },
          //the threshold is optional
          threshold: 1000 //if the request isn't faster then the threshold, a notification is sent
        },
        {
          name: 'post-request',
          method: 'POST',
          data: {file: 'SGVsbG8gd29ybGQhCg=='},
          test: function (response, reqObj) {
            if (response == 'sucess') {
              return true;
            }
            return false;
          }
        }
      ]
    }
  ],
  //file to append the output to (additional to stdout)
  //this doesn't log error messages
  logfile: '/opt/watchdog/log', //optional
  errorlog: '/opt/watchdog/errorlog', //optional
  //timeout in seconds
  timeout: 10,
  //watchdog interval in minutes
  interval: 5.5,
  email: {
    from: "Foo Bar <foo@bar.baz>",
    to: "someone@somewhere.tld",
    subject: "watchdog notification"
  }
};
```
