$(function() {
    $('table').dataTable({
        "ordering": false,
		"filter": false,
		"info": false,
		"lengthChange": false,
		"paginate": false,
        "language": {
			"url": "/lib/js/data-tables/Portuguese-Brasil.json"
		}
    });

    $("#sel").select2({
        placeholder: _("Enter the participant e-mail..."),
        minimumInputLength: 3,
        tags: function(options) {
            var url = "/caravana/ajax-buscar-participante/termo/" + options.term;
            $.getJSON(url, null, function(json) {
                options.callback(json);
            });
        }
    });

    $('a.deletar').click(function () {
        var url = $(this).attr('href');
        alertify.confirm(_('Are you sure you want to delete this participant from the caravan?'), function() {
            window.location = url;
        }).set('reverseButtons', true);
        return false;
    });
});
