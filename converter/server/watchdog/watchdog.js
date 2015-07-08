#!/usr/bin/node
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

var mailTransporter = nodemailer.createTransport(sendmailTransport());

//send an email
function sendMail(content) {
  var email = clone(config.email);
  email.text = content;

  mailTransporter.sendMail(email, function (error, info) {
    if (error) {
      return process.stderr.write(error + '\n');
    }
  });
}

//timeout that get's called by 
function timeout(passedResult) {
  var result = clone(passedResult); //clone to prevent race conditions
  var email = ""; //email to send

  //Go through all of the results
  Object.keys(result.services).forEach(
    function (service) {

      if (result.services[service].notify && (result.services[service].ping === false)) {
        email += "Service '" + service + "' not available.\n"
      }

      if (result.services[service].requests) {
        Object.keys(result.services[service].requests).forEach(
          function (req) {
            //Send notifications
            if (result.services[service].notify) {
              if (!result.services[service].requests[req].response) {
                email += "Service '" + service + "': Request '" + req + "' didn't respond.\n";
              }
              else if (!result.services[service].requests[req].success) {
                email += "Service '" + service + "': Request '" + req + "' responded incorrectly.\n";
              }

              if (result.services[service].requests[req].threshold_reached) {
                email += "Service '" + service + "': Request '" + req + "' reached it's threshold. It took " + result.services[service].requests[req].time + "ms.\n";
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

  if (email != "") {
    sendMail(email);
  }

  process.stdout.write(JSON.stringify(result) + '\n');
}

//this function get's called in regular intervals
function watch() {
  var result = {};

  result.timestamp = Date.now() / 1000; //Unix Timestamp
  result.services = {};

  config.services.forEach(
    function (service, index) {
      var urlObj = url.parse(service.url);

      result.services[service.name] = result.services[service.name] ? result.services[service.name] : {};

      //store if a notification should be sent for this service
      result.services[service.name]['notify'] = service.notify ? service.notify : false;

      if (service.ping) {
        //default value 'false' for ping
        result.services[service.name]['ping'] = false;

        //ping the host
        ping.promise.probe(urlObj.hostname).then(
          function (state) {
            result.services[service.name] = result.services[service.name] ? result.services[service.name] : {};
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
            throw new Error('No request function, this shouldn\'t happen');
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
              requestFunction = request[req.method.toLowerCase()];
          }

          result.services[service.name]['requests'][req.name].startTime = Date.now(); //time before the request
          requestFunction(
            {url: url.format(requestUrl), form: req.data, timeout: (config.timeout + 1) * 1000}, function (error, response, body) {
              var stopTime = Date.now(); //time after the answer to the request came back
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
                }
              }
            }
          );
        }
      );
    }
  );

  setTimeout(timeout, config.timeout * 1000, result);
}

var watcher = setInterval(watch, config.interval * 60 * 1000);
