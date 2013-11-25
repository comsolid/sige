/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

$(document).ready(function() {
   oTable = $('table').dataTable({
      "sPaginationType" : "full_numbers",
      "aaSorting": [ ],
      "bFilter": false
   });

   $("#termo").focus();
    
   //getValores();
	
   $("#termo").keyup(function() {
      getValores();
		
   });

});

function getValores() {
   $("#loading").show();
   var termo = $("#termo").val();
   var url = "/admin/caravana/ajax-buscar/termo/" + termo;
   $.getJSON(url, null, function(json) {
      oTable.fnClearTable();
      if (json.size > 0) {
        oTable.fnAddData(json.itens);
      }
   }).complete(function() {
      $("#loading").hide();
   });
}