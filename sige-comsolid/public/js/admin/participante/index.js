var oTablePes;
$(document).ready(function() {
	
   $("#termo").select();
	$('#radioset_tipo_busca').buttonset();
   
   buscar();
	
	oTablePes = $('#pessoas').dataTable( {
		"sPaginationType" : "full_numbers",
		"aaSorting": [  ],
		"bFilter": false
	});

	$("#termo").autocomplete({
		source: function() {
			buscar();
		}
	});
	
   $('input:radio').click(function() {
		$("#termo").select();
      buscar();
   });

	$(document).delegate('a.situacao', 'click', function() {
      //console.log($(this).attr('data-url'));
      presenca($(this).attr('data-url'));
      $("#termo").select();
   });
});

function buscar() {
   $("#loading").show();
	var idEncontro = $("#id_encontro").val();
	var termo = $("#termo").val();
	var tipo_busca= $('input:radio[name=t_busca]:checked').val();
   
   $.ajax({
      url: "/admin/participante/ajax-buscar/tipo/"+tipo_busca+"/idEncontro/"+idEncontro+"/termo/"+termo,
      contentType: "application/x-www-form-urlencoded; charset=utf-8;",
      type: 'POST',
      success: function( json ) {
         oTablePes.fnClearTable();
         if(json.size>0) {
            oTablePes.fnAddData(json.aaData);
         }
      },
      complete: function() {
         $("#loading").hide();
      }
   });
}

function presenca(url) {
   $.getJSON(url, function(json) {
      if (json.ok) {
         mostrarMensagem("div.success", json.msg);
      } else if (json.erro != null) {
         mostrarMensagem("div.error", json.erro);
      }
   }).complete(function() {
      buscar();
   });
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