
$(function() {

    function gerarRelatorio() {
        var url = '/admin/relatorios/ajax-inscricoes-municipio-15-mais';
        $.getJSON(url, function(json) {
            if (json.ok) {
                Morris.Bar({
                    element: 'bar-chart',
                    barColors: ['#4da74d', '#0b62a4'],
                    data: json.array,
                    xkey: 'municipio',
                    ykeys: ['confirmados', 'num'],
                    labels: ['Num. confir.', 'Num. insc.'],
                    stacked: true
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
