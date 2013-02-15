
$(function() {
   oTable = $('table').dataTable( {
		"sPaginationType" : "full_numbers",
		"aaSorting": [  ]
	});
   
   $("#sel").select2({
      placeholder: "Digite o e-mail do palestrante...",
      minimumInputLength: 3,
      tags: function(options) {
         // https://groups.google.com/forum/#!msg/select2/bOF3CPXsqjI/YmR3yHN2yc4J
         var url = "/evento/ajax-buscar-participante/termo/" + options.term;
         $.getJSON(url, null, function(json) {
               options.callback(json);
         });
      }
   });
   
   $('.tooltip').tipsy({gravity: 's'});
});
