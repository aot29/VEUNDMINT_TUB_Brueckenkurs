#!/usr/bin/node
'use strict'

var ping = require('ping');
var jquery = require('jquery');
var config = require('./config');

//get information from a given URL
//
//returns an object of the form:
//  {
//      url: url,
//      host: hostname,
//      path: path,
//      protocol: protocol
//  }
function getUrlInfo(url) {
  var regex = new RegExp('(http(?:s|))://([a-z0-9_\\.]+)/(.*)$', 'gi');
  var match = regex.exec(url);
  if (match === null) {
    throw new SyntaxError('"' + url + '" is not a valid URL.');
  }

  return {
    url: url,
    protocol: match[1],
    host: match[2],
    path: match[3]
  }
}

//timeout that get's called by 
function timeout(result) {
  console.log(JSON.stringify(result));
}

function pingCallback(state, result, path) {
  result[path] = result[path] ? result[path] : {};
  result[path]['ping'] = state.alive;
}


//this function get's called in regular intervals
function watch() {
  var result = {};

  result.timestamp = Date.now() / 1000; //Unix Timestamp

  config.services.forEach(
    function (service, index) {
      var urlInfo = getUrlInfo(service.url); //extract information from the URL
      ping.promise.probe(urlInfo.host).then(
        function (state) {
          pingCallback(state, result, service.name);
        }
      );
    }
  );

  setTimeout(timeout, 1000, result); //TODO: use the timeout from the configuration
}

var watcher = setInterval(watch, config.interval /* * 60 */ * 1000); //TODO: Use minutes instead of seconds
