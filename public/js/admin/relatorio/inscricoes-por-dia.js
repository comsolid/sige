
$(function() {
    function gerarRelatorio() {
        var url = '/admin/relatorios/ajax-inscricoes-por-dia';
        var params = {
            format: 'json'
        };
        $.getJSON(url, params, function(json) {
            if (json.ok) {
                Morris.Line({
                    element: 'line-chart',
                    data: json.array,
                    xkey: 'data',
                    ykeys: ['num'],
                    labels: ['Num. insc.'],
                    dateFormat: function (x) {
                        var date = new Date(x);
                        return dateFormat(date);
                    },
                    xLabelFormat: function (x) {
                        return dateFormat(x);
                    }
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
        $('#line-chart').html('');
        gerarRelatorio();
    });
});
