$(function () {

    $('.btn-group').tooltip({
		selector:'[data-toggle="tooltip"]',
        container: 'body'
    });

	$('span[data-moment]').each(function(idx, item) {
		var $item = $(item);
		var date = $item.attr('data-moment');
		$item.html(moment(date).fromNow());
	});
});
