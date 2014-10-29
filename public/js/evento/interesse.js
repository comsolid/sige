'use strict';

var oTable;
$(function() {
	oTable = $('table').dataTable({
		"ordering": false,
		"filter": false,
		"info": false,
		"lengthChange": false,
		"paginate": false,
		"language": {
			"url": "/lib/js/data-tables/Portuguese-Brasil.json"
		}
	});

   $("#termo").select();
   getValores();
   $("#termo").autocomplete({
      source: function() {
         getValores();
      }
   });

	// evento Usado quando seleciar uma data do evento
	$('input:radio').change(function() {
		getValores();
	});

	$(document).delegate('a.marcar', 'click', function(event) {
		addEvento($(this).attr('id'));
	});
});

function getDataEvento() {
	return $('input:radio.data_evento:checked').val();
}

function getTipoEvento() {
	return $('input:radio.tipo_evento:checked').val();
}

function getValores() {
	$("#loading").show();
	var termo = $("#termo").val();
	var data_evento = getDataEvento();
	var tipo_evento = getTipoEvento();

	$.getJSON("/evento/ajax-buscar/termo/"+termo+"/id_tipo_evento/"+tipo_evento+"/data/"+data_evento, function(json){
		oTable.fnClearTable();
		if (json.size > 0) {
			oTable.fnAddData(json.itens);
		}
	}).complete(function() {
		$("#loading").hide();
	});
}

function addEvento(id) {

	if (id > 0) {
		$.getJSON("/evento/ajax-interesse/id/"+id, function(json) {
			if (json.ok) {
				mostrarMensagem("div#msg-success", _("Interesting event bookmarked."));
			} else if (json.erro != null) {
				mostrarMensagem("div#msg-error", json.erro);
			}
		}).complete(function() {
			getValores();
		});
	}
}
