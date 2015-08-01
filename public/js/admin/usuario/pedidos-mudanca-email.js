
$(function () {
    moment.lang('pt-br');
    $('span[data-moment]').each(function(idx, item) {
		var $item = $(item);
		var date = $item.attr('data-moment');
		$item.html(moment(date, 'DD/MM/YYYY HH:mm').fromNow());
	});

    $('.btn-status').click(function () {
        var self = this;
        alertify.confirm(_('This action can not be undone. Do you really wish to continue?'), function () {
            window.location = $(self).attr('href');
        }).set('reverseButtons', true).set('defaultFocus', 'cancel');
        return false;
    });
});
