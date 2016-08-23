var config       = require('../config')
if(!config.tasks.scripts) return

var gulp         = require('gulp')
var gulpif       = require('gulp-if')
var browserSync  = require('browser-sync')
//var sass         = require('gulp-sass')
//var sourcemaps   = require('gulp-sourcemaps')
var handleErrors = require('../lib/handleErrors')
//var autoprefixer = require('gulp-autoprefixer')
var path         = require('path')
var concat       = require('gulp-concat')
var using        = require('gulp-using')

var paths = {
  //src: path.join(config.root.src, config.tasks.css.src, '/**/*.{' + config.tasks.css.extensions + '}'),
  src: config.tasks.scripts.src,
  dest: path.join(config.root.dest, config.tasks.scripts.dest)
}

var scriptsTask = function () {
  return gulp.src(paths.src)
    .pipe(using({prefix:'Using script', path:'relative', color:'yellow', filesize:true}))
    .pipe(gulpif(global.production,
      concat('app.js')
    ))
    .pipe(gulp.dest(paths.dest))
    .pipe(browserSync.stream())
}

gulp.task('scripts', scriptsTask)
module.exports = scriptsTask
