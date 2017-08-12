
var gulp = require('gulp')
var replace = require('gulp-replace-task')
var browserSync = require('browser-sync').create()

gulp.task('default', function() {
    var config = require('./gulp/default.json')

    gulp.src(config.file_patterns, { base: './' })
        .pipe(replace({
            patterns: config.patterns,
            usePrefix: false
        }))
        .pipe(gulp.dest('build'))
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
