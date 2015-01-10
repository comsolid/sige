
$(function() {
	$('.display').dataTable({
      //"sPaginationType" : "full_numbers",
      'aaSorting': [ ],
      'bFilter': false
	});

	$('a.btn').button();
	$('#tabs').tabs();

	$('span[data-moment]').each(function(idx, item) {
		var $item = $(item);
		var date = $item.attr('data-moment');
		$item.html(moment(date).fromNow());
	});
});
