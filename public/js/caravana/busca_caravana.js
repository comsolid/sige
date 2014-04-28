$(document).ready(function () {
    getValores();

    $("#nome_caravana").keyup(function () {
        getValores();

    });

    $('a').click(function (event) {
        addEvento($(this).attr('id'));
    });

});

function getValores() {
    var nomeCaravana = $("#nome_caravana").val();

    $.ajax({
        type: "POST",
        url: "../caravana/busca/nome_caravana/" + nomeCaravana,
        success: function (AJAX_RESPONSE_OK) {
            $(AJAX_RESPONSE_OK).find("busca").each(function () {
                $('#resultadoCaravana').html($(this).find("tbody").text());
            });
        }
    });
}