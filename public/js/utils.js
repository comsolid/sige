
function mostrarMensagem(id, msg) {
    var aux = (msg !== null) ? msg : _("Unknow error.");
    $(id).html(aux).show("blind", 500, esconderMensagem(id));
}

function esconderMensagem(id) {
    setTimeout(function () {
        $(id + ":visible").fadeOut();
    }, 3000);
}