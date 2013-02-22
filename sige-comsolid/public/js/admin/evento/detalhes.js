
$(function() {
	oTable = $('.display').dataTable({
      //"sPaginationType" : "full_numbers",
      "aaSorting": [ ],
      "bFilter": false
	});

	$("a.btn").button();
	$("#tabs").tabs();
});