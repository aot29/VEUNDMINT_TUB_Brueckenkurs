var requirejs = require('requirejs');

var RJSConfig = function() {
	return requirejs.config({
		shim: {},
		paths: {}
	});
}

module.exports = RJSConfig;