
var oTable;

$(function() {
	oTable = $('table').dataTable( {
		//"sPaginationType" : "full_numbers",
		"aaSorting": [  ]
	});
   
   $('.tooltip').tipsy({gravity: 's'});
});