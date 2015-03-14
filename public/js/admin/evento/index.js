$(function() {
    var oTable = $('table#eventos').dataTable({
        'ordering': true,
		'filter': false,
		'info': true,
		'lengthChange': true,
		'paginate': true,
		'language': {
			'url': '/lib/js/data-tables/Portuguese-Brasil.json'
		}
    });

    $('#termo').focus();

    function buscar() {
        $('#loading').show();
        var termo = $('#termo').val();
        var tipo = $('input:radio.tipo_evento:checked').val();
        var situacao = $('input:radio.situacao:checked').val();
        var searchBy = $('input:radio.search_by:checked').val();
        var url = '/admin/evento/ajax-buscar';
        var data =  {
            termo: termo,
            tipo: tipo,
            situacao: situacao,
            searchBy: searchBy
        };

        $.getJSON(url, data, function(json) {
            oTable.fnClearTable();
            if (json.size > 0) {
                oTable.fnAddData(json.itens);
            }
        }).complete(function() {
            $('#loading').hide();
        });
    }
    // buscar ao iniciar página.
    buscar();

    $('#termo').autocomplete({
        source: function() {
            buscar();
        }
    });

    $('input:radio').change(function() {
        buscar();
        $('#termo').select();
    });
});
