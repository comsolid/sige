
function dateFormat(date) {
   return sprintf("%02d/%02d/%04d",
      (date.getUTCDate() + 1),
      (date.getMonth() + 1),
      date.getFullYear()
   );
}

function mostrarMensagem( id, msg ) {
   var aux = (msg != null) ? msg : "Erro desconhecido.";
   $(id).html( aux ).show( "blind", 500, esconderMensagem(id) );
}

function esconderMensagem(id) {
   setTimeout(function() {
      $( id + ":visible" ).fadeOut();
   }, 3000 );
}
