
function mostrarMensagem(id, msg) {
    var aux = (msg !== null) ? msg : _('Unknow error.');
    $(id).html(aux).show('blind', 500, esconderMensagem(id));
}

function esconderMensagem(id) {
    setTimeout(function () {
        $(id + ':visible').fadeOut();
    }, 3000);
}

$.ajaxSetup({
    global: true,
    error: function(xhr, status, err) {
        // if http status is 403, send user to login again
        if (xhr.status === 403) {
           window.location = '/login';
        }
    }
});
