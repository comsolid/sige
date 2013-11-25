/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

$(function() {
   oTable = $('table').dataTable( {
		"sPaginationType" : "full_numbers",
		"aaSorting": [  ]
	});
   
   $("#sel").select2({
      placeholder: "Digite o e-mail do participante...",
      minimumInputLength: 3,
      tags: function(options) {
         // https://groups.google.com/forum/#!msg/select2/bOF3CPXsqjI/YmR3yHN2yc4J
         /*var data = {results: [
               {id: 1, text: 'ruby'},
               {id: 2, text: 'java'},
               {id: 3, text: 'python'}
            ]};
         options.callback(data);*/
         
         // {"result":[{"id":"7","text":"julioneves@gmail.com"}]}
         var url = "/caravana/ajax-buscar-participante/termo/" + options.term;
         $.getJSON(url, null, function(json) {
               options.callback(json);
         });
      }
   });
});