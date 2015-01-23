
$(function() {

    function gerarRelatorio() {
        var url = '/admin/relatorios/ajax-inscricoes-horario';
        $.getJSON(url, function(json) {
            if (json.ok) {
                Morris.Bar({
                    element: 'bar-chart',
                    data: json.array,
                    xkey: 'horario',
                    ykeys: ['num'],
                    labels: ['Num. insc.']
                });
            } else if (json.error) {
                alertify.error(json.error);
            }
        }).complete(function() {
            $('.fa-refresh').removeClass('fa-spin');
        });
    }

    gerarRelatorio();

    $('#reload').click(function() {
        $('.fa-refresh').addClass('fa-spin');
        $('#bar-chart').html('');
        gerarRelatorio();
    });
});
