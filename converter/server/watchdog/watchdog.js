#!/usr/bin/node

var ping = require('ping'); //load ping module
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
  console.log(result);
}

function pingCallback(state, result, path) {
  result[path] = result[path] ? result[path] : {};
  result[path]['ping'] = state;
}


//this function get's called in regular intervals
function watch() {
  var result = {};
  console.log('\n\n\n\nwatching\n');
  ping.promise.probe(getUrlInfo(config.URL.feedback).host).then(
    function (state) {
      pingCallback(state, result, 'feedback');
    }
  );

  ping.promise.probe(getUrlInfo(config.URL.userdata).host).then(
    function (state) {
      pingCallback(state, result, 'userdata');
    }
  );

  ping.promise.probe(getUrlInfo(config.URL.course).host).then(
    function (state) {
      pingCallback(state, result, 'course');
    }
  );

  result.timeout = setTimeout(timeout, 1000, result);
}

var watcher = setInterval(watch, config.interval /* * 60 */ * 1000);
