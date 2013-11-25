
$(function() {
   oTable = $('table#eventos').dataTable({
      "sPaginationType" : "full_numbers",
      "aaSorting": [ ],
      "bFilter": false
	});
   
   $("#termo").select();
   $("#radioset_evento, #radioset_situacao").buttonset();
   
   // buscar ao iniciar página.
   buscar();
   
   $("#termo").autocomplete({
		source: function() {
			buscar();
		}
	});
   
   $("input:radio").click(function() {
      buscar();
      $("#termo").select();
   });
});

function buscar() {
   $("#loading").show();
   var termo = $("#termo").val();
   var tipo = $("input:radio.tipo_evento:checked").val();
   var situacao = $("input:radio.situacao:checked").val();
   var url = "/admin/evento/ajax-buscar/termo/" + termo
      + "/tipo/" + tipo + "/situacao/" + situacao;
   $.getJSON(url, function(json) {
      oTable.fnClearTable();
      if (json.size > 0) {
         oTable.fnAddData(json.itens);
      }
   }).complete(function() {
      $("#loading").hide();
   });
}