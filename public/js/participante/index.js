
$(function() {

	var removeButton = $('a.close[data-toggle="tooltip"]');
	removeButton.tooltip();
	removeButton.click(function () {
		var id_evento = $(this).attr('data-id-evento');
		alertify.confirm(_('Are you sure?'), function() {
            $.ajax({
                url: '/evento/ajax-desfazer-interesse',
                type: 'POST',
                data: {
                    id_evento: id_evento,
					format: 'json'
                },
                success: function (json) {
                    if (json.ok) {
                        $('#panel_event_' + id_evento).slideUp(500);
                        alertify.success(json.msg);
                    } else if (json.error) {
                        alertify.alert(json.error);
                    }
                },
                error: function (jqXHR, textStatus, errorThrown) {
                    alertify.alert(textStatus + ': ' + errorThrown);
                }
            });
		}).set('reverseButtons', true);
	});
});
