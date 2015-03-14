
$(function() {

	$('span[data-moment]').each(function(idx, item) {
		var $item = $(item);
		var date = $item.attr('data-moment');
		$item.html(moment(date, 'DD/MM/YYYY HH:mm').fromNow());
	});

	var btnValidated = $('#btn-validated');
	btnValidated.on('mouseover', function () {
		var action = btnValidated.attr('data-btn-action');
        var defaultAction = btnValidated.attr('data-btn-default-action');
		var title = btnValidated.attr('data-btn-title');
		btnValidated.addClass(action).removeClass(defaultAction).html(title);
	});

	btnValidated.on('mouseout', function () {
		var action = btnValidated.attr('data-btn-action');
        var defaultAction = btnValidated.attr('data-btn-default-action');
		var title = btnValidated.attr('data-btn-default-title');
		btnValidated.removeClass(action).addClass(defaultAction).html(title);
	});
    
    var btnPresented = $('#btn-presented');
	btnPresented.on('mouseover', function () {
		var action = btnPresented.attr('data-btn-action');
        var defaultAction = btnPresented.attr('data-btn-default-action');
		var title = btnPresented.attr('data-btn-title');
		btnPresented.addClass(action).removeClass(defaultAction).html(title);
	});

	btnPresented.on('mouseout', function () {
		var action = btnPresented.attr('data-btn-action');
        var defaultAction = btnPresented.attr('data-btn-default-action');
		var title = btnPresented.attr('data-btn-default-title');
		btnPresented.removeClass(action).addClass(defaultAction).html(title);
	});
});
