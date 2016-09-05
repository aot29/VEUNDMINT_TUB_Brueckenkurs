var config       = require('../config')
if(!config.tasks.fonts) return

var gulp         = require('gulp')
var path         = require('path')
var using        = require('gulp-using')

var paths = {
  dest: path.join(config.root.dest, config.tasks.fonts.dest)
}

var fontsTask = function() {
  return gulp.src(config.tasks.fonts.src)
    .pipe(using({prefix:'Using font', path:'relative', color:'yellow', filesize:true}))
    .pipe(gulp.dest(paths.dest))
}

gulp.task('fonts', fontsTask)
module.exports = fontsTask
