var oTable;var giCount=0;
$(document).ready( function() {
	//getValores();
	oTable = $('table').dataTable( {
		 "bProcessing": true
	       // "bServerSide": true//,
	       // "sAjaxSource": "../evento/busca/nome_evento/"+$("#nome_evento").val()+"/id_tipo_evento/"+getTipoEvento()+"/data/"+getDataEvento()+"/idEncontro/"+$("#idEncontro").val(),
	      
			});
	getValores();
	$("#nome_evento").keyup(function () {
		getValores();
		
		
   });

	// evento Usado quando seleciar uma data do evento	
	$('input:radio').click(function() {	               
		getValores();            
			});
	$('a').click(function(event) {
			addEvento($(this).attr('id')); });
	

});

function getDataEvento(){
	var data_evento="";
	$('input:radio[name=data_evento]').each(function() {
        //Verifica qual está selecionado
        if ($(this).is(':checked')){
        	data_evento=$(this).val();
        }
        });
	return data_evento;
}

function getTipoEvento(){
	var tipo_evento=0;
	$('input:radio[name=tipo_evento]').each(function() {
        //Verifica qual está selecionado
        if ($(this).is(':checked')){
       	 tipo_evento=parseInt($(this).val());
        }
    
    });
	return tipo_evento;
}

function getValores(){
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
      	$.getJSON("../evento/busca/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val(), function(json){
      		oTable.fnClearTable();
      		if(json.size>0)
      		oTable.fnAddData(json.aaData);
      		$('a').click(function(event) {
				addEvento($(this).attr('id')); });
    	  });
     /* $.ajax({
			type: "POST",
			dataType: "jdom",
			url: "../evento/busca/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val(),
			//data: "/5/acao/busca/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val(),
			success: function(AJAX_RESPONSE_OK){

			
	  			//$(AJAX_RESPONSE_OK).find("busca").each(function(){
	  			
					///document.getElementById('idnota').value=$(this).find("produto").attr("value");
					//document.getElementById('descbusca').focus();
					//alert($(this).find("produto").text());totaitens
	  				//$('#resultado').html($(this).find("tbody").text());
	  				
	  				//var q=jQuery.parseJSON('[["Trident","Internet Explorer 4.0","Win 95+","4","X"],["Other browsers","All others","-", "-", "U"]]');
	  				//alert(q.aaData);
	  				oTable.fnAddData(AJAX_RESPONSE_OK);
	  				$('a').click(function(event) {
	  					addEvento($(this).attr('id')); });
	  				//oTable = $('table').dataTable( {
	  				//	"sPaginationType" : "full_numbers",
	  				//	"aaSorting": [  ]
	  				//});
		      //  }); //close each( 	
	  				alert(AJAX_RESPONSE_OK);
			
			}
		});*/
}
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
		$.getJSON("../evento/busca/acao/add/nome_evento/"+descEvento+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento+"/idEncontro/"+$("#idEncontro").val()+"/evento/"+evento+"/idPessoa/"+$("#idPessoa").val(), function(json){
      		if(json.erro!=true){
			oTable.fnClearTable();
	      		if(json.size>0)
	      		oTable.fnAddData(json.aaData);
      		}
      		$('a').click(function(event) {
					addEvento($(this).attr('id')); });
    	  });
		/*
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
	  					
	  				}else{
	  					alert($(this).find("tbody").text());
	  				}
	  				
		        }); //close each( 				  			
			
			}
		});
		*/
}