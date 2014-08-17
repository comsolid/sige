module.exports = function (grunt) {

    grunt.loadNpmTasks('grunt-contrib-watch');

    grunt.initConfig({
        watch: {
            options: {
                livereload: true
            },
            css: {
                files: ['public/css/**/*.css', 'public/lib/css/**/*.css'],
                tasks: ['default']
            },
            js: {
                files: ['public/js/**/*.js', 'public/lib/js/**/*.js'],
                tasks: ['default']
            },
            html: {
                files: ['application/views/scripts/**/*.phtml'],
                tasks: ['default']
            }
        }
    });
    grunt.registerTask("default", ["watch"]);
};
