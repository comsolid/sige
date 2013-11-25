$(document).ready(function() {
	getValores();
	
	$("#nome_caravana").keyup(function() {
		getValores();
		
	});
	
	$('a').click(function(event) {
		addEvento($(this).attr('id')); });

});

function getValores() {
	var nomeCaravana = $("#nome_caravana").val();
	
	$.ajax( {
		type : "POST",
		url : "../caravana/busca/nome_caravana/"+nomeCaravana,

		// data:
		// "/5/acao/busca/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val(),
		success : function(AJAX_RESPONSE_OK) {

			$(AJAX_RESPONSE_OK).find("busca").each(function() {

				// /document.getElementById('idnota').value=$(this).find("produto").attr("value");
					// document.getElementById('descbusca').focus();
					// alert($(this).find("produto").text());totaitens
				$('#resultadoCaravana').html($(this).find("tbody").text());
				/*$('a').click(function(event) {
  					/*validaCaravana($(this).attr('id')); });*/

			}); // close each(
		}
	});

}
/*
function validadaCaravana(idCaravana){
	var descEvento=$("#nome_evento").val();
	var data_evento="";
	var tipo_evento=0;
	$('input:radio[name=data_evento]').each(function() {
        //Verifica qual está selecionado
        if ($(this).is(':checked')){
        	data_evento=$(this).val();
        }
        });
      $('input:radio[name=tipo_evento]').each(function() {
         //Verifica qual está selecionado
         if ($(this).is(':checked')){
        	 tipo_evento=parseInt($(this).val());
         }
     
     });
	
	if(parseInt(idCaravana).val())>0)
	alert(idCaravana);
      $.ajax({
			type: "POST",
			url: "../public/evento/busca/acao/add/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val()+"/evento/"+evento+"/idPessoa/"+$("#idPessoa").val(),
			//data: "/5/acao/busca/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val(),
			success: function(AJAX_RESPONSE_OK){
			
	  			$(AJAX_RESPONSE_OK).find("busca").each(function(){  
	  				
					///document.getElementById('idnota').value=$(this).find("produto").attr("value");
					//document.getElementById('descbusca').focus();
					//alert($(this).find("produto").text());totaitens
	  				
	  				/*$('a').click(function(event) {
	  					alert($(this).attr('id')); });
	  				if($(this).find("tbody").attr("erro")=='false'){
	  					$('#resultado').html($(this).find("tbody").text());
	  					$('a').click(function(event) {
		  					addEvento($(this).attr('id')); });
	  				}else{
	  					alert($(this).find("tbody").text());
	  				}
	  				
		        }); //close each( 				  			
			
			}
		});
}*/

