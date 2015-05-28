
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

	var termo = $('#termo');
	var current_conference = $('#id_encontro');
    termo.select();

	var loading = $('#loading');

	function startLoading() {
		loading.addClass('fa-spinner fa-spin').removeClass('fa-search');
	}

	function stopLoading() {
		loading.removeClass('fa-spinner fa-spin').addClass('fa-search');
	}

	function buscar() {
		var regex = /\+e(\d+)p(\d+)\+/g; // e.g. +e55p123456+
		var params = regex.exec(termo.val());
		if (params) {
			validarTicket(params[1], params[2]);
		} else {
			buscarPorTermo();
		}
	}

	function validarTicket(id_encontro, id_pessoa) {
		if (id_encontro !== current_conference.val()) {
			alertify.warning(_('This ticket is not from this conference.'));
		} else {
			var url = '/u/confirmar/' + id_pessoa;
			presenca(url);
			termo.val('').focus(); // always clean up the text and focus back!
		}
	}

	function buscarPorTermo() {
		startLoading();
		var tipo_busca = $('input:radio[name=t_busca]:checked').val();

		$.ajax({
			url: '/admin/participante/ajax-buscar/',
			type: 'POST',
			data: {
				tipo: tipo_busca,
				termo: termo.val(),
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

    termo.autocomplete({
        source: function() {
            buscar();
        }
    });

	// evento Usado quando seleciar uma data do evento
	$('input:radio').change(function() {
		termo.select();
		buscar();
	});

	function presenca(url) {
		var params = {
			format: 'json'
		};
		$.getJSON(url, params, function(json) {
			if (json.ok) {
				alertify.success(json.msg);
			} else if (json.erro !== null) {
				alertify.error(json.erro);
			}
		}).complete(function () {
			buscar();
		});
	}

    $(document).delegate('a.situacao', 'click', function() {
        presenca($(this).attr('data-url'));
        termo.select();
		return false;
    });
});
