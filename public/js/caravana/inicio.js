
var oTable;

$(function() {
	oTable = $('table').dataTable( {
		"sPaginationType" : "full_numbers",
		"aaSorting": [  ]
	});

   $("#bSearch").button({
      icons: {
         primary: "ui-icon-search"
      }
   });

 
});