
$(function() {
    $('#hora_inicio').change(function() {
        var index = $(this).children('option:selected').index();
        console.log(index);
        $('#hora_fim :nth-child(' + (index + 1) + ')').prop('selected', true);
    });
});
