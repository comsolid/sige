/**
 * @deprecated use /js/admin/evento/index.js
 */

$(document).ready( function() {
	getValores();
	$("#nome_evento").keyup(function () {
		getValores();
   });

	// evento Usado quando seleciar uma data do evento	
	$('input:radio').click(function() {
		//alert($(this).val()); 
			               
		getValores();            
			});
	/*$('a').click(function(event) {
			addEvento($(this).attr('id')); });*/
});

function getValores(){
	var descEvento=$("#nome_evento").val();
	var tipo_evento
	var atividade
	
	
	
	$('input:radio[name=tipo_evento]').each(function() {
        //Verifica qual está selecionado
        if ($(this).is(':checked')){
        	tipo_evento=parseInt($(this).val());
        }
        });
      $('input:radio[name=atividades]').each(function() {
         //Verifica qual está selecionado
         if ($(this).is(':checked')){
        	 atividade=parseInt($(this).val());
         }
     
     });
      
      $.ajax({
			type: "POST",
			url: "../evento/buscaadmin/nome_evento/"+descEvento+"/tipo_evento/"+tipo_evento+"/atividade/"+atividade,
			//data: "/5/acao/busca/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val(),
			success: function(AJAX_RESPONSE_OK){

			
	  			$(AJAX_RESPONSE_OK).find("busca").each(function(){
	  			
					///document.getElementById('idnota').value=$(this).find("produto").attr("value");
					//document.getElementById('descbusca').focus();
					//alert($(this).find("produto").text());totaitens
	  				$('#resultadoAtividades').html($(this).find("tbody").text());
	  				/*$('a').click(function(event) {
	  					addEvento($(this).attr('id')); });*/
	  				
		        }); //close each( 				  			
			
			}
		});
}
/*
function addEvento(evento){
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
	
	if(parseInt($("#idPessoa").val())>0 && evento > 0)
      $.ajax({
			type: "POST",
			url: "../evento/busca/acao/add/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val()+"/evento/"+evento+"/idPessoa/"+$("#idPessoa").val(),
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
	  					oTable = $('table').dataTable( {
		  						"sPaginationType" : "full_numbers",
		  						"aaSorting": [  ]
		  					});
	  				}else{
	  					alert($(this).find("tbody").text());
	  				}
	  				
		        }); //close each( 				  			
			
			}
		});
}*/