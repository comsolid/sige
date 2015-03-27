/*
 * TODO LIST CUSTOM PLUGIN
 * -----------------------
 * This plugin depends on iCheck plugin for checkbox and radio inputs
 *
 * @type plugin
 * @usage $("#todo-widget").todolist( options );
 */
(function($) {

    $.fn.todolist = function(options) {
        // Render options
        var settings = $.extend({
            //When the user checks the input
            onCheck: function(ele) {},
            //When the user unchecks the input
            onUncheck: function(ele) {}
        }, options);

        return this.each(function() {

            if (typeof $.fn.iCheck != 'undefined') {
                $('input', this).on('ifChecked', function(event) {
                    var ele = $(this).parents("li").first();
                    ele.toggleClass("done");
                    settings.onCheck.call(ele);
                });

                $('input', this).on('ifUnchecked', function(event) {
                    var ele = $(this).parents("li").first();
                    ele.toggleClass("done");
                    settings.onUncheck.call(ele);
                });
            } else {
                $('input', this).on('change', function(event) {
                    var ele = $(this).parents("li").first();
                    ele.toggleClass("done");
                    settings.onCheck.call(ele);
                });
            }
        });
    };
}(jQuery));
