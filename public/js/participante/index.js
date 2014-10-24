
$(function() {

	var removeButton = $('a.close[data-toggle="tooltip"]');
	removeButton.tooltip();
	removeButton.click(function () {
		var id_evento = $(this).attr('data-id-evento');
		bootbox.confirm(_("Are you sure?"), function (result) {
			if (result) {
				$.ajax({
					url: '/evento/ajax-desfazer-interesse',
					type: 'POST',
					data: {
						id_evento: id_evento
					},
					success: function (json) {
						if (json.ok) {
							$("#panel_event_" + id_evento).slideUp(500);
						} else if (json.error) {
							bootbox.alert(json.error);
						}
					},
					error: function (jqXHR, textStatus, errorThrown) {
						bootbox.alert(_("An error occour. Please try again later. Details:")
							+ textStatus + ": " + errorThrown);
					}
				});
			}
		});
	});
});
