$(function() {
    var oTablePes = $('table').dataTable({
		'ordering': false,
		'filter': false,
		'info': false,
		'lengthChange': false,
		'paginate': false,
		'language': {
			'url': '/lib/js/data-tables/Portuguese-Brasil.json'
		}
	});
    var loading = $('#loading');

    function startLoading() {
        loading.addClass('fa-spinner fa-spin').removeClass('fa-search');
    }

    function stopLoading() {
        loading.removeClass('fa-spinner fa-spin').addClass('fa-search');
    }

    function buscar() {
        startLoading();
        var termo = $('#termo').val();
        var tipo_busca = $('input:radio[name=t_busca]:checked').val();
        var params = {
            buscar_por: tipo_busca,
            termo: termo,
            format: 'json'
        };
        var url = '/admin/config/ajax-buscar-usuarios/';

        $.getJSON(url, params, function(json) {
            oTablePes.fnClearTable();
            if (json.size > 0) {
                oTablePes.fnAddData(json.aaData);
            } else if (json.erro !== null) {
                console.log(json.erro);
            }
        }).complete(function() {
            stopLoading();
        });
    }

    $('#termo').select();
    buscar();

    $('#termo').autocomplete({
        source: function() {
            buscar();
        }
    });

    // evento Usado quando seleciar uma data do evento
	$('input:radio').change(function() {
		$('#termo').select();
		buscar();
	});
});
