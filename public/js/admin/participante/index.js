
$(document).ready(function () {

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
    $('#termo').select();

	var loading = $('#loading');

	function startLoading(){
		loading.addClass('fa-spinner fa-spin').removeClass('fa-search');
	}

	function stopLoading() {
		loading.removeClass('fa-spinner fa-spin').addClass('fa-search');
	}

	function buscar() {
		startLoading();
		var idEncontro = $('#id_encontro').val();
		var termo = $('#termo').val();
		var tipo_busca = $('input:radio[name=t_busca]:checked').val();

		$.ajax({
			url: '/admin/participante/ajax-buscar/',
			type: 'POST',
			data: {
				tipo: tipo_busca,
				idEncontro: idEncontro,
				termo: termo,
				format: 'json'
			},
			success: function (json) {
				oTablePes.fnClearTable();
				if (json.size > 0) {
					oTablePes.fnAddData(json.aaData);
				}
			},
			complete: function () {
				stopLoading();
			}
		});
	}

    buscar();

    $('#termo').autocomplete({
        source: function () {
            buscar();
        }
    });

	// evento Usado quando seleciar uma data do evento
	$('input:radio').change(function() {
		$('#termo').select();
		buscar();
	});

	function presenca(url) {
		var params = {
			format: 'json'
		};
		$.getJSON(url, params, function (json) {
			if (json.ok) {
				alertify.success(json.msg);
			} else if (json.erro !== null) {
				alertify.error(json.erro);
			}
		}).complete(function () {
			buscar();
		});
	}

    $(document).delegate('a.situacao', 'click', function () {
        presenca($(this).attr('data-url'));
        $('#termo').select();
		return false;
    });
});
