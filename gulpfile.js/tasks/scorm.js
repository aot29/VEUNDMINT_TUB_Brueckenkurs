var config       = require('../config')

var gulp         = require('gulp')
var scormManifest = require('gulp-scorm-manifest')
var zip = require('gulp-zip');
var gulpSequence    = require('gulp-sequence')
var gutil = require('gulp-util');


var scormManifestTask = function () {
    gulp.src('./public/**')
    .pipe(scormManifest({
      version: '1.2',
      courseId: 'TOC-1',
      SCOtitle: 'Intro Title',
      moduleTitle: 'Onlinebrückenkurs Mathematik',
      launchPage: 'index.html',
      fileName: 'imsmanifest.xml'
    }))
    .pipe(gulp.dest('./public'))
}

var scormArchiveTask = function () {
  gulp.src(['**/*', '!scormModule.zip', '!js/mathjax/**'], {cwd: 'public/'})
  .pipe(zip('scormModule.zip'))
  .pipe(gulp.dest('./public'))
}

/*
  Creates a small archive without images
 */
var scormSmallArchiveTask = function () {
  gulp.src(['**', '!scormModule.zip', '!images/**', '!js/mathjax/**'], {cwd: 'public/'})
  .pipe(zip('scormModule.zip'))
  .pipe(gulp.dest('./public'))
}

var scormTask = function() {
  gulpSequence('scormManifest', 'scormArchive');
}

gulp.task('scormManifest', scormManifestTask);
gulp.task('scormArchive', scormArchiveTask)

gulp.task('scorm', ['scormManifest'], scormArchiveTask);
gulp.task('scormSmall', ['scormManifest'], scormSmallArchiveTask);
module.exports = [scormArchiveTask, scormManifestTask];
