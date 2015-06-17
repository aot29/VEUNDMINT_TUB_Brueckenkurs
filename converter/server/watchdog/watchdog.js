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

console.log(config);
console.log('feedback', getUrlInfo(config.URL.feedback));
console.log('userdata', getUrlInfo(config.URL.userdata));
console.log('course', getUrlInfo(config.URL.course));
