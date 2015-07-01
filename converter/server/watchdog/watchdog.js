#!/usr/bin/node
'use strict'

var ping = require('ping');
var request = require('request');
var config = require('./config');
var url = require('url');
var querystring = require('querystring');
var merge = require('object-merge');

//timeout that get's called by 
function timeout(result) {
  //cleanup
  Object.keys(result.services).forEach(
    function (service) {
      if (!result.services[service].requests) {
        return
      }
      Object.keys(result.services[service].requests).forEach(
        function (req) {
          if (result.services[service].requests[req].response == false) {
            delete result.services[service].requests[req].startTime;
          }
        }
      );
    }
  );

  console.log(JSON.stringify(result));
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
              delete result.services[service.name]['requests'][req.name].startTime;
              result.services[service.name]['requests'][req.name].time = stopTime - startTime;
              if (!error) {
                result.services[service.name]['requests'][req.name].response = true;
                try {
                  result.services[service.name]['requests'][req.name].success = req.test(body);
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
