
$(function() {

	$('table').dataTable({
		'ordering': false,
		'filter': true,
		'info': true,
		'lengthChange': true,
		'paginate': true,
		'language': {
			'url': '/lib/js/data-tables/Portuguese-Brasil.json'
		}
	});
});
