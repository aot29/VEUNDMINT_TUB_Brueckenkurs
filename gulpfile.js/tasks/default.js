var gulp            = require('gulp')
var gulpSequence    = require('gulp-sequence')

var defaultTask = function(cb) {
  gulpSequence('clean', ['fonts', 'images', 'scripts'], ['css', 'mathjax', 'html'], 'scormTest', 'inject', cb)
}

gulp.task('default', defaultTask)
module.exports = defaultTask
