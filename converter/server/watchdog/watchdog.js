#!/usr/bin/node --use_strict
/* Copyright (C) 2015 KIT (www.kit.edu), Author: Max Bruckner (FSMaxB)
 *
 *     This file is part of the VE&MINT program compilation
 *     (see www.ve-und-mint.de).
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 2 of the License,
 *     or any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see http://www.gnu.org
 */
'use strict'

var ping = require('ping');
var request = require('request');
var config = require('./config');
var url = require('url');
var querystring = require('querystring');
var merge = require('merge');
var clone = require('clone');
var nodemailer = require('nodemailer');
var sendmailTransport = require('nodemailer-sendmail-transport');
var fs = require('fs');
var freespace = require('freespace-nix');
var stream = require('stream');
var base64 = require('js-base64').Base64;

/*
 * Deobfuscate mailer password and username
 */
if (config.mailoptions.auth.base64 === true) {
  config.mailoptions.auth.user = base64.decode(config.mailoptions.auth.user);
  config.mailoptions.auth.pass = base64.decode(config.mailoptions.auth.pass);
}

var mailTransporter = nodemailer.createTransport(config.mailoptions);


/*
 * global mail queue of the form:
 * { "timestamp": "Mail text here" }
 */
var mailqueue = {};

//read in the mailqueue from a file
try {
  mailqueue = JSON.parse(fs.readFileSync(config.mailqueue, 'utf8'));
} catch(e) {
  mailqueue = {};
}

var run = true; //run the watchdog?
//if the commandline parameter '--send-mails' is provided, send mails and exit
process.argv.forEach(function (argument, index) {
  if (argument === '--send-mails') {
    run = false;
    if (process.argv[index + 1] && (process.argv[index + 1] != "")) {
      //send the text of the following parameter as email
      queueMail(0, process.argv[index + 1]);
    } else {
      sendMails();
    }
  }
});


// initialize log rotation
var logrotateStream = require('logrotate-stream');
if (config.logfile && (typeof config.logfile == 'object')) {
  //create readable stream, then pipe it to a logrotated stream
  var logStream = new stream.PassThrough;
  var logPipe = logrotateStream(config.logfile);
  logStream.pipe(logPipe);

  //register error handlers
  function logWriteFailed(error) {
    var errorMessage = "ERROR: Failed writing to log file'" + config.logfile.file + "': " + error;
    errorLog(errorMessage);
    queueMail(0, errorMessage);
  }
  logPipe.on('error', logWriteFailed);
  logStream.on('error', logWriteFailed);
}
if (config.errorlog && (typeof config.errorlog == 'object')) {
  //create readable stream, then pipe it to a logrotated stream
  var errorlogStream = new stream.PassThrough;
  var errorlogPipe = logrotateStream(config.errorlog);
  errorlogStream.pipe(errorlogPipe);

  //register error handlers
  function errorlogWriteFailed(error) {
    var errorMessage = "ERROR: Failed writing to log file'" + config.errorlog.file + "': " + error;
    errorLog(errorMessage);
    queueMail(0, errorMessage);
  }
  errorlogStream.on('error', errorlogWriteFailed);
  errorlogPipe.on('error', errorlogWriteFailed);
}

//send email when starting
if (run && (config.mailOnStart === true)) {
  queueMail(0, "Watchdog started.");
}

//log to logfile
function log(message) {
  process.stdout.write(message + '\n');

  //write to log file
  if (logStream instanceof stream.PassThrough) {
    logStream.write(message + '\n');
  }
}

//log an error
function errorLog(message) {
  process.stderr.write(message + '\n');

  //write to errorlog file
  if (errorlogStream instanceof stream.PassThrough) {
    errorlogStream.write(message + '\n');
  }
}

//add a message to the mail queue, if timestamp is 0, the current time is used
function queueMail(timestamp, message) {
  if (message == "") {
    return;
  }
  timestamp = (timestamp == 0) ? Math.round(Date.now() / 1000) : timestamp;

  if (typeof config.email === 'object') {
    if (mailqueue[timestamp]) { //if a mail with this timestamp is already queued, append to it
      mailqueue[timestamp] += '\n' + message;
    } else {
      mailqueue[timestamp] = message;
    }
  }
  sendMails();
}

//write a backup of the mailqueue to a file
function writeMailQueue() {
  //write a backup of the mailqueue to a file
  fs.writeFile(config.mailqueue, JSON.stringify(mailqueue), function (error) {
    if (error) {
      errorLog("ERROR: Failed to save mailqueue to '" + config.mailqueue + "'");
    }
  });
}

//send emails, optionally runs a callback when finished
function sendMails(callback) {
  writeMailQueue();

  var email = clone(config.email);

  for (var key in mailqueue) {
    var date = new Date(1000 * key); //key is the timestamp
    email.text = date.toTimeString() + ' ' + date.toDateString() + '\n';
    email.text += mailqueue[key];
    mailTransporter.sendMail(email, function (error, info) {
      if (error) {
        return errorLog('ERROR: ' + JSON.stringify(error));
      } else {
        //remove mail from queue
        delete mailqueue[this.key];
        writeMailQueue();
      }
    }.bind({key: key})); //bind makes sure that the current value of key is accessible from the callback, not only the last value
  }
}

/*
 * Check the disk usage for every directory
 * specified in 'diskusage' in the config file.
 */
function checkDiskUsage(result) {
  result.diskusage = {};

  //go through all the directories to check
  config.diskusage.forEach(function (value) {
    freespace.df(value.path, function (error, data) {
      result.diskusage[value.path] = {success: false, percent_used: data.percent_used};
      if ((error !== undefined) && (error !== "")) {
        result.diskusage[value.path].success = false;
        errorLog('ERROR: Failed to get disk usage.');
        result.email += 'ERROR: Failed to get disk usage.\n';
        return;
      }

      if (data.percent_used > value.notify_percentage) {
        result.email += 'Disk usage limit exceeded for "' + value.path + '" (' + data.percent_used + '%)\n';
        return;
      }

      result.diskusage[value.path].success = true;
    })
  });
}

//timeout that collects all the results
function timeout(passedResult) {
  var result = clone(passedResult); //clone to prevent race conditions

  //Go through all of the results
  Object.keys(result.services).forEach(
    function (service) {

      if (result.services[service].notify && (result.services[service].ping === false)) {
        result.email += "Service '" + service + "' not available.\n"
      }

      if (result.services[service].requests) {
        Object.keys(result.services[service].requests).forEach(
          function (req) {
            //Send notifications
            if (result.services[service].notify) {
              if (!result.services[service].requests[req].response) {
                result.email += "Service '" + service + "': Request '" + req + "' didn't respond.\n";
              }
              else if (!result.services[service].requests[req].success) {
                result.email += "Service '" + service + "': Request '" + req + "' responded incorrectly.\n";
              }

              if (result.services[service].requests[req].threshold_reached) {
                result.email += "Service '" + service + "': Request '" + req + "' reached it's threshold. It took " + result.services[service].requests[req].time + "ms.\n";
              }
            }

            //cleanup
            if (result.services[service].requests[req].response == false) {
              delete result.services[service].requests[req].startTime;
            }
          }
        );
      }

      delete result.services[service].notify;
    }
  );

  queueMail(result.timestamp, result.email);

  log(JSON.stringify(result));
}

//this function gets called in regular intervals
function watch() {
  //object where the results of the requests are collected
  var result = {};

  result.timestamp = Math.round(Date.now() / 1000); //Unix Timestamp
  result.services = {};
  result.email = "";

  //check the disk usage if configuration for it exists
  if (Array.isArray(config.diskusage)) {
    checkDiskUsage(result);
  }

  //go through all of the services
  config.services.forEach(
    function (service, index) {
      var urlObj = url.parse(service.url);

      result.services[service.name] = result.services[service.name] ? result.services[service.name] : {};

      //store if a notification should be sent for this service
      result.services[service.name]['notify'] = service.notify ? service.notify : false;

      //ping a service's host
      if (service.ping) {
        //default value 'false' for ping
        result.services[service.name]['ping'] = false;

        //ping the host
        ping.promise.probe(urlObj.hostname).then(
          function (state) {
            result.services[service.name]['ping'] = state.alive;
          }
        );
      }

      //make requests
      service.requests.forEach(
        function (req, reqIndex) {
          //default values for this request
          result.services[service.name]['requests'] = result.services[service.name]['requests']
            ? result.services[service.name]['requests']
            : {};
          result.services[service.name]['requests'][req.name] = {response: false, success: false, time: null};
          if (req.threshold) {
            result.services[service.name]['requests'][req.name].threshold_reached = true;
          }

          var requestFunction = function () { //this function is to be overwritten in the following switch-case
            errorLog("ERROR: No request function, this shouldn't happen!");
            throw new Error('No request function, this shouldn\'t happen!');
          };
          var requestUrl = url.parse(service.url);
          switch (req.method.toUpperCase()) {
            case 'GET':
              requestFunction = request.get;
              //construct the GET-Request by hand because the 'request' module doesn't seem
              //to work with GET requests.
              var requestQuery = merge(querystring.parse(requestUrl.search), req.data);
              requestUrl.search = querystring.stringify(requestQuery);
              break;
            default:
              //set the request function (eg. post(...) for POST requests)
              requestFunction = request[req.method.toLowerCase()];
          }

          result.services[service.name]['requests'][req.name].startTime = Date.now(); //save current time before the request
          //now make the actual request
          requestFunction(
            {url: url.format(requestUrl), form: req.data, timeout: (config.timeout + 1) * 1000}, //configuration
            function (error, response, body) { //request callback
              var stopTime = Date.now(); //current time after the answer to the request came back
              var startTime = result.services[service.name]['requests'][req.name].startTime;
              result.services[service.name]['requests'][req.name].time = stopTime - startTime;

              //check if the threshold was reached
              if (req.threshold && ((stopTime - startTime) < req.threshold)) {
                result.services[service.name]['requests'][req.name].threshold_reached = false;
              } else {
                result.services[service.name]['requests'][req.name].threshold_reached = true;
              }

              delete result.services[service.name]['requests'][req.name].startTime;
              if (!error) {
                result.services[service.name]['requests'][req.name].response = true;
                try {
                  result.services[service.name]['requests'][req.name].success = req.test(body, response);
                } catch (error) {
                  errorlog("ERROR: Exception in the callback from config.js: " + error);
                }
              }
            }
          );
        }
      );
    }
  );

  //now that all the requests are dispatched set a timeout that collects the results
  setTimeout(timeout, config.timeout * 1000, result);
}

/*
 * How the asynchronous logic of this program works:
 *
 * Every config.interval minutes, the watch function get's called. It creates
 * a new 'result' object to store the results of the current 'watch' (not a clock).
 * 'watch' then makes all of the requests specified in the configuration and passes
 * the result object along to them (so no global result object is used, if two
 * 'watch' functions would run at the same time, both of them would have different
 * result objects).
 *
 * After dispatching all of the requests, a timeout is started. The requests that
 * arrive before the timeout will add their results to the 'result' object. Once
 * triggered, the timeout 'collects' the 'result' object, processes it and prints
 * it out. All requests that arrive after the timeout has been called won't be
 * included in the 'collection' and therefore are handled like they didn't arrive at all.
 */
if (run) {
  var watcher = setInterval(watch, config.interval * 60 * 1000);
}
