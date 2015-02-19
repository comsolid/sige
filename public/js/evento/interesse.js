
$(function() {
	var oTable = $('table').dataTable({
		'ordering': false,
		'filter': false,
		'info': false,
		'lengthChange': false,
		'paginate': false,
		'language': {
			'url': '/lib/js/data-tables/Portuguese-Brasil.json'
		}
	});

	function getDataEvento() {
		return $('input:radio.data_evento:checked').val();
	}

	function getTipoEvento() {
		return $('input:radio.tipo_evento:checked').val();
	}

	function addEvento(id) {

		if (id > 0) {
	        var url = '/evento/ajax-interesse/id/' + id;
			$.getJSON(url, function(json) {
				if (json.ok) {
	                alertify.success(_('Interesting event bookmarked.'));
				} else if (json.erro !== null) {
	                alertify.error(json.erro);
				}
			}).complete(function() {
				getValores();
			});
		}
	}

	function getValores() {
		$('#loading').show();
		var termo = $('#termo').val();
		var data_evento = getDataEvento();
		var tipo_evento = getTipoEvento();
	    var url = '/evento/ajax-buscar/';

		var params = {
			termo: termo,
			id_tipo_evento: tipo_evento,
			data: data_evento
		};

		$.getJSON(url, params, function(json){
			oTable.fnClearTable();
			if (json.size > 0) {
				oTable.fnAddData(json.itens);
			}
		}).complete(function() {
			$('#loading').hide();
		});
	}

    $('#termo').select();
    getValores();
    $('#termo').autocomplete({
        source: function() {
            getValores();
        }
    });

	// evento Usado quando seleciar uma data do evento
	$('input:radio').change(function() {
		getValores();
	});

	$(document).delegate('a.marcar', 'click', function() {
		addEvento($(this).attr('id'));
	});
});
