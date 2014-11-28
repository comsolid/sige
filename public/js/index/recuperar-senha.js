
$(function () {
    $('#email').focus();
    $('#submit').click(function () {
        $(this).val('Enviando...').addClass('disabled');
    });
});
