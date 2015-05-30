
var gulp = require('gulp');
var replace = require('gulp-replace-task');

gulp.task('default', function() {
    var config = require('./gulp/default.json');

    gulp.src(config.file_patterns, { base: './' })
        .pipe(replace({
            patterns: config.patterns,
            usePrefix: false
        }))
        .pipe(gulp.dest('build'));
});
