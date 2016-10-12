var config       = require('../config')
var gulp         = require('gulp')
var gutil = require('gulp-util');
var spawn = require('child_process').spawn;
var gulpSequence    = require('gulp-sequence')
var path         = require('path');

var pdfTask = function() {
  return gulp.src(path.join(config.root.src, '**/*'))
    .pipe(gulp.dest(config.root.dest));
}

module.exports = pdfTask;
gulp.task('pdf', pdfTask);
