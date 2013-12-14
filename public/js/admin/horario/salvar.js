
$(function() {
   $("#hora_inicio").change(function() {
      var index = $("#hora_inicio option:selected").index();
      $("#hora_fim option:eq(" + index + ")").attr('selected', 'selected');
   });
   
   $('.display').dataTable({
      //"sPaginationType" : "full_numbers",
      "aaSorting": [],
      "bFilter": false
   });
});