
$(function() {
   oTablePes = $('table').dataTable( {
		"sPaginationType" : "full_numbers",
		"aaSorting": [  ],
		"bFilter": false
	});
   
   $("#termo").select();
   $("#radioset_tipo_busca").buttonset();
   buscar();
   
   $("#termo").autocomplete({
		source: function() {
			buscar();
		}
	});
   
   $('input:radio').click(function() {
		$("#termo").select();
      buscar();
   });
});

function buscar() {
   $("#loading").show();
   var termo = $("#termo").val();
   var buscar_por= $('input:radio[name=buscar_por]:checked').val();
   var url = "/admin/config/ajax-buscar-usuarios/buscar_por/"+buscar_por+"/termo/"+termo;
   
   $.getJSON(url, function(json){
      oTablePes.fnClearTable();
      if(json.size>0) {
         oTablePes.fnAddData(json.aaData);
      } else if (json.erro != null) {
         console.log(json.erro);
      }
   }).complete(function() {
      $("#loading").hide();
   });
}