var config       = require('../config')
if(!config.tasks.fonts) return

var gulp         = require('gulp');
var path         = require('path');
var inject       = require('gulp-inject');
var bowerFiles = require('main-bower-files');
var browserSync  = require('browser-sync');

var exclude = path.normalize('!**/{' + config.tasks.html.excludeFolders.join(',') + '}/**')

var paths = {
  src: [path.join(config.root.src, config.tasks.html.src, '/**/*.{' + config.tasks.html.extensions + '}'), exclude],
  dest: path.join(config.root.dest, config.tasks.html.dest),
  injectFiles: config.tasks.html.injectFiles
}

var injectTask = function() {
  return gulp.src(path.join(config.root.dest, config.tasks.html.src, '/**/*.{' + config.tasks.html.extensions + '}'))
    .pipe(inject(gulp.src(['./public/css/app.css', './public/js/mathjax/MathJax.js', './public/js/app.js'], {
      read: false,
      ignorePath: 'public'
    }), {
      transform: function (filepath, file, i, length) {
        if (filepath.includes("js/mathjax/MathJax.js")) {
          filepath += '?config=TeX-AMS-MML_HTMLorMML';
        }
        return inject.transform.apply(inject.transform, arguments);
      },
      relative: true
    }))
    .pipe(gulp.dest(paths.dest))
    .on('end', browserSync.reload)
}

gulp.task('inject', injectTask)
module.exports = injectTask
