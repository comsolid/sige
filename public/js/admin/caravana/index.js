
$(document).ready(function() {
    var loading = $('#loading');

	function startLoading(){
		loading.addClass('fa-spinner fa-spin').removeClass('fa-search');
	}

	function stopLoading() {
		loading.removeClass('fa-spinner fa-spin').addClass('fa-search');
	}

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

    function getValores() {
        startLoading();
        var termo = $('#termo').val();
        var url = '/admin/caravana/ajax-buscar/';
        var params = {
            termo: termo,
            format: 'json'
        };
        $.getJSON(url, params, function(json) {
            oTable.fnClearTable();
            if (json.size > 0) {
                oTable.fnAddData(json.itens);
            }
        }).complete(function() {
            stopLoading();
        });
    }
    getValores();

    var termo = $('#termo');
    termo.focus();
    termo.autocomplete({
        source: function() {
            getValores();
        }
    });
    termo.keyup(function (event) {
        if (event.target.value === '') {
            getValores();
        }
    });

});
