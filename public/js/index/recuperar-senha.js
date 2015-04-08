
$(function () {
    $('#email').focus();
    $('#submit').click(function () {
        $(this).val('Sending...').addClass('disabled');
    });
});
