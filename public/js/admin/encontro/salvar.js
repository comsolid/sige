
$(function() {
    $('#nome_encontro').select();

    $('.date')
        .mask('99/99/9999')
        .datetimepicker({
            locale: 'pt-br',
            format: 'DD/MM/YYYY'
        });
});
