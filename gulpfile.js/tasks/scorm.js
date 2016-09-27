var config       = require('../config')

var gulp         = require('gulp')
var scormManifest = require('gulp-scorm-manifest')
var zip = require('gulp-zip');
var gulpSequence    = require('gulp-sequence')

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
  gulp.src('**/*', {cwd: 'public/'})
  .pipe(zip('scormModule.zip'))
  .pipe(gulp.dest('./public'))
}

var scormTask = function() {
  gulpSequence('scormManifest', 'scormArchive');
}

gulp.task('scormManifest', scormManifestTask);
gulp.task('scormArchive', scormArchiveTask)

gulp.task('scorm', ['scormManifest'], scormArchiveTask);
module.exports = [scormArchiveTask, scormManifestTask];
