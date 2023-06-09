var config       = require('../config')

var gulp         = require('gulp')
var sourcemaps   = require('gulp-sourcemaps')
var handleErrors = require('../lib/handleErrors')
var path         = require('path')
var concat       = require('gulp-concat')
var using        = require('gulp-using')
var browserSync  = require('browser-sync')

var paths = {
  //src: path.join(config.root.src, config.tasks.css.src, '/**/*.{' + config.tasks.css.extensions + '}'),
  src: ["./bower_components/MathJax/**/*"],
  dest: path.join(config.root.dest, 'js/mathjax/')
}

var mathjaxTask = function () {
  return gulp.src(paths.src, {base: "./bower_components/MathJax/"})
    //.pipe(using({prefix:'Using mathjax scripts', path:'relative', color:'yellow', filesize:true}))
    .pipe(gulp.dest(paths.dest))
    .pipe(browserSync.stream())
}

gulp.task('mathjax', mathjaxTask)
module.exports = mathjaxTask
