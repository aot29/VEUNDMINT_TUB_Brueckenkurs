var gulp            = require('gulp')
var gulpSequence    = require('gulp-sequence')
var getEnabledTasks = require('../lib/getEnabledTasks')

var defaultTask = function(cb) {
  var tasks = getEnabledTasks('watch')
  //gulpSequence('clean', tasks.assetTasks, tasks.codeTasks, 'static', 'watch', cb)
  gulpSequence('clean', ['fonts', 'images'], 'scripts', 'css', 'html', 'watch', cb)
}

gulp.task('default', defaultTask)
module.exports = defaultTask
