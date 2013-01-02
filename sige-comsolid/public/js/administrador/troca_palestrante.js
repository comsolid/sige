var oTablePes;
$(document).ready(function() {
	
	/*getValoresCoordenacao();
	getValoresOrganizacao();
	$("#nome_pessoa").keyup(function() {
		getValores();
		
	});*/
	
	oTablePes = $('#pessoas').dataTable( {
		"sPaginationType" : "full_numbers",
		"aaSorting": [  ]
	});
	$("#nome_pessoa").keyup(function() {
		getValores();
	});
	getValores();
});

function getValores() {
	var idEncontro = $("#id_encontro").val();
	var nomePessoa = $("#nome_pessoa").val();
	
	$.getJSON("../alterapalestrante/idEncontro/"+idEncontro+"/nomePessoa/"+nomePessoa, function(json){
		oTablePes.fnClearTable();
  		if(json.size>0)
  			oTablePes.fnAddData(json.aaData);
  		//$('a').click(function(event) {
			//addEvento($(this).attr('id')); });
	  });
	/*$.ajax( {
		type : "POST",
		url : "administrador/busca/idEncontro/"+idEncontro+"/nomePessoa/"+nomePessoa,

		// data:
		// "/5/acao/busca/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val(),
		success : function(AJAX_RESPONSE_OK) {

			$(AJAX_RESPONSE_OK).find("busca").each(function() {

				// /document.getElementById('idnota').value=$(this).find("produto").attr("value");
					// document.getElementById('descbusca').focus();
					// alert($(this).find("produto").text());totaitens
				$('#resultado').html($(this).find("tbody").text());

			}); // close each(
		}
	});*/

}