
$(function() {
	oTable = $('table#horarios').dataTable({
      //"sPaginationType" : "full_numbers",
      "aaSorting": [ ],
      "bFilter": false
	});

	$("a.btn").button();
	$("#tabs").tabs();
});