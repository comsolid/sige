
$(function () {
    $('table').dataTable( {
        'ordering': true,
		'filter': false,
		'info': true,
		'lengthChange': true,
		'paginate': true,
		'language': {
			'url': '/lib/js/data-tables/Portuguese-Brasil.json'
		}
    });

    $('#participantes').select2({
        placeholder: 'Digite o e-mail do participante...',
        minimumInputLength: 3,
        tags: function(options) {
            var url = '/admin/presenca/ajax-buscar-participante/termo/' + options.term;
            $.getJSON(url, null, function(json) {
                options.callback(json);
            });
        }
    });

    $('.delete').click(function () {
        var self = this;
        alertify.confirm('Deseja realmente deletar?', function () {
            window.location = $(self).attr('href');
        }).set('reverseButtons', true).set('defaultFocus', 'cancel');
        return false;
    });
});
