$(function () {

    gerarRelatorio();

    $("#reload").click(function () {
        $(".icon-refresh").addClass("icon-spin");
        $("#donut-chart").html("");
        gerarRelatorio();
    });
});

function gerarRelatorio() {
    var url = "/admin/relatorios/ajax-inscricoes-sexo";
    $.getJSON(url, function (json) {
        if (json.ok) {
            Morris.Donut({
                element: 'donut-chart',
                data: json.array
            });

            var total = 0;
            for (var i in json.array) {
                total += json.array[i].value;
            }
            $("#total").html(Jed.sprintf(_('Total registrations: <strong>%d</strong>'), total));
        } else if (json.erro != null) {
            mostrarMensagem("div.error", json.erro);
        }
    }).complete(function () {
        $(".icon-refresh").removeClass("icon-spin");
    });
}