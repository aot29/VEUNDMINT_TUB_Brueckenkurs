var config       = require('../config')
if(!config.tasks.images) return

var gulp         = require('gulp')
var imagemin     = require('gulp-imagemin')
var path         = require('path')

var paths = {
  //src: path.join(config.root.src, config.tasks.css.src, '/**/*.{' + config.tasks.css.extensions + '}'),
  src: config.tasks.images.src,
  dest: path.join(config.root.dest, config.tasks.images.dest)
}

var imagesTask = function() {
  return gulp.src(paths.src)
    .pipe(imagemin())
    .pipe(gulp.dest(paths.dest));
}

var infolderImagesTask = function () {
  return gulp.src('./tu9onlinekurstest/html/de/**/*.png', {base: "./tu9onlinekurstest/"})
    //.pipe(imagemin())
    .pipe(gulp.dest(config.root.dest))
}

gulp.task('images', imagesTask)
gulp.task('infolderImages', infolderImagesTask)
module.exports = [imagesTask, infolderImagesTask]
