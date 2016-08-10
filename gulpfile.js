var gulp = require('gulp');

// gulp package variables
var changed = require('gulp-changed'),
    jshint = require ('gulp-jshint'),
    concat = require ('gulp-concat'),
    uglify = require ('gulp-uglify'),
    rename = require('gulp-rename'),
    imagemin = require ('gulp-imagemin'),
    clean = require('gulp-clean'),
    htmlmin = require('gulp-htmlmin'),
    autoprefixer = require ('gulp-autoprefixer'),
    minifyCSS = require ('gulp-minify-css'),
    browserSync = require ('browser-sync'),
    gutil = require('gulp-util'),
    striplog = require('gulp-strip-debug'),
    environments = require('gulp-environments'),
    preprocess = require('gulp-preprocess'),
    inject = require('gulp-inject'),
    reload = browserSync.reload;

// environment variables
var development = environments.development,
    production = environments.production;

// output and input paths are defined here
var paths = {
  src: './tu9onlinekurstest/',
  dest: './tu9onlinekurstest/app/',
  imgSrc: './tu9onlinekurstest/images/**/*',
  imgDest: './tu9onlinekurstest/app/images',
  htmlSrc: './tu9onlinekurstest/**/*.html',
  htmlDest: './tu9onlinekurstest/app/',
  cssSrc: [
    './tu9onlinekurstest/css/**/*.css',
    './tu9onlinekurstest/bootstrap/css/bootstrap.css'
  ],
  cssDest: './tu9onlinekurstest/app/css',
  jsSrc: [
    './tu9onlinekurstest/js/**/*',
    './tu9onlinekurstest/bootstrap/js/bootstrap.js'
  ],
  jsDest: './tu9onlinekurstest/app/js'
};

// Static Server + watching scss/html files
gulp.task('serve', function() {

    browserSync.init({
        server: paths.src
    });

    //gulp.watch("app/scss/*.scss", ['sass']);
    //gulp.watch("./tu9onlinekurstest/**/*.html").on('change', reload);
});

gulp.task('inject', function () {

  var cssAndJsSrc = paths.cssSrc.concat(paths.jsSrc);

  var target = gulp.src(['./tu9onlinekurstest/*.html', './tu9onlinekurstest/html/**/*.html']);
  // It's not necessary to read the files (will speed up things), we're only after their paths:
  var sources = gulp.src(cssAndJsSrc, {read: false});

  target.pipe(inject(sources, {relative: true}))
    .pipe(gulp.dest(paths.src));
});

gulp.task('css', function() {
  return gulp.src(paths.cssSrc)
    .pipe(concat('app.css'))
    .pipe(gulp.dest(paths.src));
});

// gulp.task('html', function() {
//   return gulp.src(paths.htmlSrc)
//     .pipe(gulp.dest(paths.src));
// });
//

gulp.task('default', ['css', 'inject', 'serve']);

//
// function browserSyncInit(baseDir, files) {
//   browserSync.instance = browserSync.init(files, {
//     startPath: '/', server: { baseDir: baseDir }
//   });
// }
//
// // starts a development server
// // runs preprocessor tasks before,
// // and serves the src and .tmp folders
// gulp.task(
//     'serve', function () {
//   browserSyncInit([
//     paths.dest
//   ], [
//     paths.dest + '/**/*.css',
//     paths.dest + '/**/*.js',
//     paths.dest + '/**/*.html'
//   ]);
// });
//
// // starts a production server
// // runs the build-prod task before,
// // and serves the dist folder
// gulp.task('serve:dist', ['build-prod'], function () {
//   //
// });
//
// gulp.task('browser-sync', function() {
//   browserSyncInit(paths.dist);
// });
//
//
// /**************************
// *** definition of tasks ***
// **************************/
//
// gulp.task('scripts', function() {
//
//   // set the file name depending to the environment
//   var destFile = production() ? 'app.min.js' : 'app.js';
//
//   // pipe the js through concat, console log stripping, uglification and then store
//   return gulp.src(paths.jsSrc)
//
//       .pipe(concat(destFile)) // concat all files in the src
//       .pipe(production(uglify())) // only uglify in env=production
//       .pipe(gulp.dest(paths.jsDest)) // save the file
//       //.on('error', gutil.log);
// });
//
// // My css files
// gulp.task('css', function() {
//
//   // Concat and minify all the css
//   return gulp.src(paths.cssSrc)
//       .pipe(concat('app.min.css')) // concat all files in the src
//       .pipe(production(minifyCSS())) // uglify them all
//       .pipe(gulp.dest(paths.cssDest)) // save the file
//       .on('error', gutil.log);
// });
//
// //compress images
// gulp.task('images', function() {
//
//   gulp.src(paths.imgSrc)
//     .pipe(changed(paths.imgDest))
//     .pipe(imagemin())
//     .pipe(gulp.dest(paths.imgDest));
// });
//
// //minify html
// gulp.task('html', function () {
//     return gulp.src(paths.htmlSrc)
//       .pipe(production(htmlmin({collapseWhitespace: true}))) // only minify in prod
//       .pipe(inject(gulp.src(paths.cssDest + '**/*.css', {read: false}), {relative: true, ignorePath: 'app'}))
//       .pipe(gulp.dest(paths.htmlDest))
//       .pipe(reload({stream: true}));
// });
//
// gulp.task('default', function() {
//   gulp.start('css', 'scripts', 'images', 'html');
//   gulp.start('serve');
// });
//
// //build everything (for production)
