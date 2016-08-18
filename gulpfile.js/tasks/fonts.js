var config       = require('../config')
if(!config.tasks.fonts) return

var gulp         = require('gulp')
var path         = require('path')


var paths = {
  dest: path.join(config.root.dest, config.tasks.fonts.dest)
}

var fontsTask = function() {
  return gulp.src(config.tasks.fonts.src, {base: './tu9onlinekurstest/fonts'})
    .pipe(gulp.dest(paths.dest))
}

gulp.task('fonts', fontsTask)
module.exports = fontsTask
