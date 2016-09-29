var config       = require('../config')

var gulp         = require('gulp')
var scormManifest = require('gulp-scorm-manifest')
var zip = require('gulp-zip');
var gulpSequence    = require('gulp-sequence')
var gutil = require('gulp-util');

var currentDate = new Date().toISOString().slice(0, 10);

var zipFileName = 'scormModule-' + currentDate + '.zip';

var scormManifestTask = function () {
    var stream = gulp.src('./public/**')
    .pipe(scormManifest({
      version: '1.2',
      courseId: 'TOC-1',
      SCOtitle: 'Onlinebrückenkurs Mathematik',
      moduleTitle: 'Onlinebrückenkurs Mathematik',
      launchPage: 'index.html',
      fileName: 'imsmanifest.xml'
    }))
    .pipe(gulp.dest('./public'));
	return stream;
}

var scormArchiveTask = function () {
  gulp.src(['**/*', '!scormModule-*.zip', '!js/mathjax/**'], {cwd: 'public/'})
  .pipe(zip(zipFileName))
  .pipe(gulp.dest('./public'))
  gutil.log(gutil.colors.green('created archive: public/' + zipFileName))
}

/*
  Creates a small archive without images
 */
var scormSmallArchiveTask = function () {
  gulp.src(['**', '!scormModule-*.zip', '!images/**', '!js/mathjax/**'], {cwd: 'public/'})
  .pipe(zip(zipFileName))
  .pipe(gulp.dest('./public'))
  gutil.log(gutil.colors.green('created archive (without images): public/' + zipFileName))
}

gulp.task('scormManifest', scormManifestTask);
gulp.task('scormArchive', scormArchiveTask);
gulp.task('scormSmallArchive', scormSmallArchiveTask);


//gulp.task('scorm', gulpSequence('scormManifest', 'scormArchive'));
gulp.task('scorm', ['scormManifest'], scormArchiveTask);
gulp.task('scormSmall', gulpSequence('scormManifest', 'scormSmallArchive'));
module.exports = [scormArchiveTask, scormManifestTask];
