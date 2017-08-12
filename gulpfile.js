
const gulp = require('gulp')
const replace = require('gulp-replace-task')
const browserSync = require('browser-sync').create()
const uglify = require('gulp-uglify')
const del = require('del')
const cssnano = require('gulp-cssnano')
const imagemin = require('gulp-imagemin')
const cache = require('gulp-cache')
const gulpUtil = require('gulp-util')
const runSequence = require('run-sequence')
const gulpCopy = require('gulp-copy')
const htmlmin = require('gulp-html-minifier')
const DEST_DIR = 'build'

gulp.task('cdnify', function() {
    const config = require('./gulp/default.json')

    gulp.src(config.file_patterns, { base: '.' })
        .pipe(replace({
            patterns: config.patterns,
            usePrefix: false
        }))
        .pipe(gulp.dest(DEST_DIR))
})

gulp.task('minify-js', function() {
    return gulp.src(['public/js/**/*.js'], {base: '.'})
        .pipe(uglify().on('error', gulpUtil.log))
        .pipe(gulp.dest(DEST_DIR))
})

gulp.task('minify-css', function() {
    return gulp.src(['public/css/**/*.css'], {base: '.'})
        .pipe(cssnano())
        .pipe(gulp.dest(DEST_DIR))
})

gulp.task('minify-img', function(){
    return gulp.src([
        'public/img/*.+(png|jpg|jpeg|gif|svg)',
        'public/css/*.+(png|jpg|jpeg|gif|svg)'
    ], {base: '.'})
        .pipe(cache(imagemin()))
        .pipe(gulp.dest(DEST_DIR))
})

/**
 * Minify html templates in-place. Use in production only!
 */
gulp.task('html-min', function () {
    gulp.src('application/**/*.html', {base: '.'})
        .pipe(htmlmin({
            collapseWhitespace: true,
            processScripts: [
                'text/x-template',
                'text/x-handlebars-template',
                'text/x-tmpl-mustache'
            ],
            keepClosingSlash: true,
            ignoreCustomFragments: [
                /\{\{[^}]*\}\}/
            ],
            removeComments: true
        }))
        .pipe(gulp.dest(DEST_DIR))
})

gulp.task('watch', function() {
    browserSync.init({
        proxy: 'localhost:8080',
        open: false
    })

    gulp.watch([
        'public/**/*.css',
        'public/**/*.js',
        'application/**/*.phtml',
        'application/**/*.html'
    ]).on('change', browserSync.reload)
})

gulp.task('clean', function () {
    return del([DEST_DIR])
})

gulp.task('base-copy', function () {
    return gulp.src([
        'application/**',
        '!application/cache/**',
        '!application/configs/*',
        'library/**',
        'resources/**'
    ]).pipe(gulpCopy(DEST_DIR))
})

gulp.task('default', function (done) {
    runSequence('clean', 'base-copy', [
        'cdnify',
        'minify-js',
        'minify-css',
        'minify-img',
        'html-min'
    ], done)
})
