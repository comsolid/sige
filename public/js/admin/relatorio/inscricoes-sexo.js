$(function () {

    function gerarRelatorio() {
        var url = '/admin/relatorios/ajax-inscricoes-sexo';
        var params = {
            format: 'json'
        };
        $.getJSON(url, params, function (json) {
            if (json.ok) {
                Morris.Donut({
                    element: 'donut-chart',
                    data: json.array
                });

                var total = 0;
                for (var i in json.array) {
                    total += json.array[i].value;
                }
                $('#total').html(Jed.sprintf(_('Total registrations: <strong>%d</strong>'), total));
            } else if (json.error) {
                alertify.error(json.error);
            }
        }).complete(function () {
            $('.fa-refresh').removeClass('fa-spin');
        });
    }

    gerarRelatorio();

    $('#reload').click(function () {
        $('.fa-refresh').addClass('fa-spin');
        $('#donut-chart').html('');
        gerarRelatorio();
    });
});
