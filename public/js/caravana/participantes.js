$(function() {
   oTable = $('table').dataTable({
      "sPaginationType": "full_numbers",
      "aaSorting": []
   });

   $("#sel").select2({
      placeholder: _("Enter the participant e-mail..."),
      minimumInputLength: 3,
      tags: function(options) {
         var url = "/caravana/ajax-buscar-participante/termo/" + options.term;
         $.getJSON(url, null, function(json) {
            options.callback(json);
         });
      }
   });
});