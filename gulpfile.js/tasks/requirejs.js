var DIST = './dist';
var rjs = require('requirejs');
var gulp = require('gulp')


var requirejsConfig = {
	name: 'veundmint',
	out: '../build/main-built.js',
	baseUrl: 'src/files/js',
	shim: {},
	paths: {
		newIntersite: '../../src/files/js/newIntersite.js'
	},
	nodeRequire: require
};

rjs.config(requirejsConfig);

var requireJsTask = function (taskReady) {
	rjs.optimize(
		requirejsConfig, 
		function (buildResponse) {
			taskReady();
		}, 
		taskReady);
}

gulp.task('requirejs', requireJsTask);

module.exports = requireJsTask