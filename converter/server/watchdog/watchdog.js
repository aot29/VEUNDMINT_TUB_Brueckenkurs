#!/usr/bin/node
'use strict'

var ping = require('ping');
var request = require('request');
var config = require('./config');
var url = require('url');

//timeout that get's called by 
function timeout(result) {
  console.log(JSON.stringify(result));
}

//this function get's called in regular intervals
function watch() {
  var result = {};

  result.timestamp = Date.now() / 1000; //Unix Timestamp

  config.services.forEach(
    function (service, index) {
      var urlObj = url.parse(service.url);

      //defaut value 'false' for ping
      result[service.name] = result[service.name] ? result[service.name] : {};
      result[service.name]['ping'] = false;

      //ping the host
      ping.promise.probe(urlObj.hostname).then(
        function (state) {
          result[service.name] = result[service.name] ? result[service.name] : {};
          result[service.name]['ping'] = state.alive;
        }
      );

      //make requests
      service.requests.forEach(
        function (req, reqIndex) {
          //default values for this request
          result[service.name]['requests'] = result[service.name]['requests'] 
            ? result[service.name]['requests'] 
            : {};
          result[service.name]['requests'][req.name] = {response: false, success: false};

          result[service.name]['requests'][req.name].startTime = Date.now();
          request[req.method.toLowerCase()](
            service.url, {form: req.data}, function (error, response, body) {
              var stopTime = Date.now();
              var startTime = result[service.name]['requests'][req.name].startTime;
              delete result[service.name]['requests'][req.name].startTime;
              result[service.name]['requests'][req.name].time = stopTime - startTime;
              if (!error) {
                result[service.name]['requests'][req.name].response = true;
                result[service.name]['requests'][req.name].success = req.test(body);
              }
            }
          );
        }
      );
    }
  );

  setTimeout(timeout, 1000, result); //TODO: use the timeout from the configuration
}

var watcher = setInterval(watch, config.interval /* * 60 */ * 1000); //TODO: Use minutes instead of seconds
