Watchdog
========

About
-----
Watchdog is a program to watch web services for their availability and automatically sending an Email if a services responds to slowly or doesn't even respond at all.

Usage
-----
Before you run this, make sure you have *nodejs* and *npm* installed. Then install the dependencies with `npm install`. If you want to send email notifications, you need to also have *sendmail* installed.

You can run it directly with `./watchdog.js` or via `node watchdog.js` (might be `nodejs watchdog.js` on some GNU/Linux distributions).

If you only want to send remaining emails, run it with the commanline parameter `--send-mails`. This parameter also accepts strings in the parameter after that and will send an email containing that string.

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

Installing nodejs manually
--------------------------
If your distribution doesn't have nodejs available as a package or it is too old, you can compile your own version of it. This requires gcc, make, python2, openssl and git.

Now follow the following steps (for up to date instructions you might want to take a look into the official installation instructions provided by NodeJS):

(this works under the assumption that you want to install NodeJS to /opt/watchdog/node)

```
# su - watchdog
$ cd /opt/watchdog
$ git clone https://github.com/nodejs/node node-src
$ cd node-src
```

Now run `git tag | sort -V` and then `git checkout vX.X.X` where `vX.X.X` is the latest version. On older versions of Debian (squeeze, wheezy) you have to use the latest version of `v0.10` because newer versions don't seem to work.

Then do the following (on Debian add `--openssl-libpath=/usr/lib/ssl` to `./configure`).

```
$ ./configure --prefix=/opt/watchdog/node
$ make
$ make install
```

`npm` will now be available under `/opt/watchdog/node/bin/npm` and `node` at `/opt/watchdog/node/bin/node`

Starting the watchdog manually
------------------------------
To run the watchdog manually as user watchdog (without systemd or Sys-V init), run the following command:

```
nohup su -c 'node /opt/watchdog/watchdog.js -- watchdog' &
```
Don't forget to replace `node` with `/opt/watchdog/node/bin/node` if necessary.

Features
--------
Watchdog performs checks on the availability of services in regular intervals. It can check the following:
* ping the host
* make an HTTP request (GET, POST etc.) and check the validity of the response
* send email notifications via sendmail or smtp
 - if sending an email fails, it will be queued so that it can be tried again later
* check if a request takes too long
* notify when disk usage exceeds a given amount
* logfile rotation
* support for obfuscated mail login data (base64 encoded to prevent shoulder surfers from seeing the plain text) **WARNING: THIS IS NO ENCRYPTION!**

Obfuscate password and username
-------------------------------
 **WARNING: THIS IS NO ENCRYPTION!**

If you're editing your configuration file and one of your coworkers happens to look on the screen at that time, they might see your plaintext smtp credentials. To prevent this you can use base64 encoded smtp passwords and user names.

To encode the password/username:
```
$ echo -n 'password' | base64
```
Don't forget to clear your bash history afterwards.

Then just paste the base64 into your configuration file and enable base64.

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
  },
  email: '', //email text that was sent (if any)
  diskusage: {
    path: {success: false, percent_used: 100} //success is also false if the disk usage couldn't be determined
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
  //directories for which to check the disk usage.
  diskusage: [
    {path: "./", notify_percentage: 99}
  ]
  //file to append the output to (additional to stdout)
  //this doesn't log error messages
  logfile: {
    file: '/opt/watchdog/log', //optional
    size: '1M', //rotate log file when this size is reached
    keep: '3', //keep 3 rotations
    compress: true //gzip compression
  },
  errorlog: {
    file: '/opt/watchdog/errorlog', //optional
    size: '1M',
    keep: 3,
    compress: true
  },
  mailqueue: 'mailqueue.json', //list of mails that remain to be sent
  //timeout in seconds
  timeout: 10,
  //watchdog interval in minutes
  interval: 5.5,
  mailOnStart: true, //send an email when watchdog is started
  mailOnStop: true, //send an email when watchdog is stopped
  email: {
    from: "Foo Bar <foo@bar.baz>",
    to: "someone@somewhere.tld",
    subject: "watchdog notification"
  },
  mailoptions: { //see https://github.com/andris9/nodemailer-smtp-transport#usage
    port: 587, // used by TLS connection
    host: "smtp.somewhere.com",
    secure: false, //has to be false when using STARTTLS, see https://github.com/andris9/Nodemailer/issues/440
    auth: {
      base64: true, //enable base 64 encoded username and password (for obfuscation)
      user: "VVNFUk5BTUU=",
      pass: "UEFTU1dPUkQ="
    },
    authMethod: "LOGIN",
    ignoreTLS: false // true -> port should be 25
  }
};
```
