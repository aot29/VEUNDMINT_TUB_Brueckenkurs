if(global.production) return

var browserSync       = require('browser-sync')
var gulp              = require('gulp')
var config            = require('../config')

var browserSyncTask = function() {

  var proxyConfig = config.tasks.browserSync.proxy || null;

  if (typeof(proxyConfig) === 'string') {
    config.tasks.browserSync.proxy = {
      target : proxyConfig
    }
  }



  //set the browsersync middleware to allow CORS requsts
  config.tasks.browserSync.middleware = function (req, res, next) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    next();
  }

  var server = config.tasks.browserSync.proxy || config.tasks.browserSync.server;

  browserSync.init(config.tasks.browserSync)
}

gulp.task('browserSync', browserSyncTask)
module.exports = browserSyncTask
