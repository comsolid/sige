var oTablePes;
$(document).ready(function() {
	
   $("#nome_pessoa").select();
	$('#radioset_tipo_busca').buttonset();
   
   getValores();
	getValoresCoordenacao();
	getValoresOrganizacao();
	
	oTablePes = $('#pessoas').dataTable( {
		"sPaginationType" : "full_numbers",
		"aaSorting": [  ],
		"bFilter": false
	});

	$("#nome_pessoa").autocomplete({
		source: function() {
			getValores();
		}
	});
	
   $('input:radio').click(function() {
		$("#nome_pessoa").select();
      getValores();
   });

	$(document).delegate('a.situacao', 'click', function() {
      //console.log($(this).attr('data-url'));
      presenca($(this).attr('data-url'));
   });
});

function getValores() {
   $("#loading").show();
	var idEncontro = $("#id_encontro").val();
	var nomePessoa = $("#nome_pessoa").val();
	var tipo_busca= $('input:radio[name=t_busca]:checked').val();
   
   $.getJSON("/admin/participante/ajax-buscar/tbusca/"+tipo_busca+"/idEncontro/"+idEncontro+"/nomePessoa/"+nomePessoa, function(json){
      oTablePes.fnClearTable();
      if(json.size>0) {
         oTablePes.fnAddData(json.aaData);
      }
   }).complete(function() {
      $("#loading").hide();
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
      getValores();
   });
}

function getValoresCoordenacao(){
	var idEncontro = $("#id_encontro").val();
	
	$.ajax( {
		
		type : "POST",
		url : "/administrador/buscacoordenacao/idEncontro/"+idEncontro,

		// data:
		// "/5/acao/busca/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val(),
		success : function(AJAX_RESPONSE_OK) {

			$(AJAX_RESPONSE_OK).find("busca").each(function() {

				// /document.getElementById('idnota').value=$(this).find("produto").attr("value");
					// document.getElementById('descbusca').focus();
					// alert($(this).find("produto").text());totaitens
				$('#resultadoCoordenacao').html($(this).find("tbody").text());

			}); // close each(
		}
	});
}

function getValoresOrganizacao(){
	var idEncontro = $("#id_encontro").val();
	
	$.ajax( {
		type : "POST",
		url : "/administrador/buscaorganizacao/idEncontro/"+idEncontro,

		// data:
		// "/5/acao/busca/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val(),
		success : function(AJAX_RESPONSE_OK) {

			$(AJAX_RESPONSE_OK).find("busca").each(function() {

				// /document.getElementById('idnota').value=$(this).find("produto").attr("value");
					// document.getElementById('descbusca').focus();
					// alert($(this).find("produto").text());totaitens
				$('#resultadoOrganizacao').html($(this).find("tbody").text());

			}); // close each(
		}
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