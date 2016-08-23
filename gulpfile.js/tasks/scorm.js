var config       = require('../config')

var gulp         = require('gulp')
var scormManifest = require('gulp-scorm-manifest')

var scormTask = function () {
    gulp.src('./public/**')
    .pipe(scormManifest({
      version: '1.2',
      courseId: 'Gulp101',
      SCOtitle: 'Intro Title',
      moduleTitle: 'Module Title',
      launchPage: 'index.html',
      fileName: 'imsmanifest.xml'
    }))
    .pipe(gulp.dest('./public'))
}

gulp.task('scorm', scormTask)
module.exports = scormTask
