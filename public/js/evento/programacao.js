$(function() {
    $('#date-tabs a').each(function (idx, el) {
        var target = $(el);
        var pane = $('#' + target.attr('aria-controls'));
        if (! pane.length) {
            target.parent().remove();
        }
    }).promise().done(function () {
        $('#date-tabs a:first').tab('show'); // Select first tab
    });
});
