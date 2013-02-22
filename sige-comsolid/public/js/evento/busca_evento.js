
var oTable;
$(function() {
   $('#radioset_data, #radioset_tipo').buttonset();
   
   oTable = $('table').dataTable({
      "bProcessing": true,
      "aaSorting": [ [1, 'asc'] ]
   });
   
   $("#termo").select();
   getValores();
   $("#termo").autocomplete({
      source: function() {
         getValores();
      }
   });

   // evento Usado quando seleciar uma data do evento	
   $('input:radio').click(function() {	               
      getValores();            
   });
   
   $(document).delegate('a.marcar', 'click', function(event) {
      addEvento($(this).attr('id'));
   });
});

function getDataEvento() {
   return $('input:radio.data_evento:checked').val();
}

function getTipoEvento() {
   return $('input:radio.tipo_evento:checked').val();
}

function getValores() {
   $("#loading").show();
   var termo = $("#termo").val();
   var data_evento = getDataEvento();
   var tipo_evento = getTipoEvento();
   
   $.getJSON("/evento/ajax-buscar/termo/"+termo+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento, function(json){
      oTable.fnClearTable();
      if (json.size > 0) {
         oTable.fnAddData(json.itens);
      }
   }).complete(function() {
      $("#loading").hide();
   });
}

function addEvento(id) {
	
   if (id > 0) {
      $.getJSON("/evento/ajax-interesse/id/"+id, function(json) {
         if (json.ok) {
            mostrarMensagem("div.success", "Evento marcado com interessante.");
         } else if (json.erro != null) {
            mostrarMensagem("div.error", json.erro);
         }
      }).complete(function() {
         getValores();
      });
   }
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