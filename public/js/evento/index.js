$(function () {

    $('.btn-group').tooltip({
		selector:'[data-toggle="tooltip"]',
        container: 'body'
    });

    moment.lang('pt-br');
	$('span[data-moment]').each(function(idx, item) {
		var $item = $(item);
		var date = $item.attr('data-moment');
		$item.html(moment(date, 'DD/MM/YYYY HH:mm').fromNow());
	});

    $('.delete').click(function () {
        var self = this;
        alertify.confirm('Deseja realmente deletar?', function () {
            window.location = $(self).attr('href');
        }).set('reverseButtons', true).set('defaultFocus', 'cancel');
        return false;
    });
});
