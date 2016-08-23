var config = require('../config')
var gulp   = require('gulp')
var path   = require('path')
var watch  = require('gulp-watch')
var browserSync = require('browser-sync')
var reload = browserSync.reload

var watchTask = function() {
  gulp.watch(["./public/*.html", "./public/css/*.css", "./public/js/*.js"]).on("change", reload);
}

gulp.task('watch', ['browserSync'], watchTask)
module.exports = watchTask
