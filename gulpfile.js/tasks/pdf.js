var config       = require('../config')
var gulp         = require('gulp')
var gutil = require('gulp-util');
var spawn = require('child_process').spawn;
var gulpSequence    = require('gulp-sequence')

var pdfTask = function() {
  // Finally execute your script below - here "ls -lA"
   var child = spawn("pdflatex",["-interaction", "nonstopmode", "-file-line-error", "veundmintkurs.tex"], {cwd: process.chdir('_tmp/tex')}),
       stdout = '',
       stderr = '';

   child.stdout.setEncoding('utf8');

   child.stdout.on('data', function (data) {
       stdout += data;
       gutil.log(data);
   });

   child.stderr.setEncoding('utf8');
   child.stderr.on('data', function (data) {
       stderr += data;
       gutil.log(gutil.colors.red(data));
       gutil.beep();
   });

   child.on('close', function(code) {
       gutil.log("Done with exit code", code);
       gutil.log("You access complete stdout and stderr from here"); // stdout, stderr
   });
}

var makeIndexTask = function() {
  // Finally execute your script below - here "ls -lA"
   var child = spawn("makeindex",["-q", "veundmintkurs"], {cwd: process.chdir('_tmp/tex')}),
       stdout = '',
       stderr = '';

   child.stdout.setEncoding('utf8');

   child.stdout.on('data', function (data) {
       stdout += data;
       gutil.log(data);
   });

   child.stderr.setEncoding('utf8');
   child.stderr.on('data', function (data) {
       stderr += data;
       gutil.log(gutil.colors.red(data));
       gutil.beep();
   });

   child.on('close', function(code) {
       gutil.log("Done with exit code", code);
       gutil.log("You access complete stdout and stderr from here"); // stdout, stderr
   });
}

module.exports = pdfTask;
gulp.task('pdfTask', pdfTask);
gulp.task('makeIndexTask', makeIndexTask);
gulp.task('pdf', gulpSequence('pdfTask', 'makeIndexTask', 'pdfTask'));
