
$(document).ready(function() {
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
        $('#loading').show();
        var termo = $('#termo').val();
        var url = '/admin/caravana/ajax-buscar/termo/' + termo;
        $.getJSON(url, null, function(json) {
            oTable.fnClearTable();
            if (json.size > 0) {
                oTable.fnAddData(json.itens);
            }
        }).complete(function() {
            $('#loading').hide();
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
