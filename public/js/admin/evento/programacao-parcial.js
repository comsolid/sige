
$(function () {
    var total_valid = $('.box-success').length;
    var total_undefined = $('.box-warning').length;

    $('#valid-events').html(total_valid);
    $('#undefined-events').html(total_undefined);
});
