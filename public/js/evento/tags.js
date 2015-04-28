
$(function() {
    $('a.close[data-toggle="tooltip"]').tooltip();

    var termo = $('#termo')
        , loading = $('#loading');

    termo.select();
    loading.hide();

    function appendToUl(id, descricao) {
        if ($('ul.list-group li').length === 0) {
            $('ul.list-group').html('');
            $('div.panel-body').css('display', 'none');
        }

        $('<li></li>', {
            html: descricao +
                  '<a href="#" onclick="return false;" ' +
                  'class="close remover pull-right" ' +
                  sprintf('data-id="%d" data-toggle="tooltip" data-placement="top" ', id) +
                  sprintf('title="%s">', _('Remove')) +
                  '<span aria-hidden="true">&times;</span><span class="sr-only">Close</span></a>',
            class: 'list-group-item',
            id: 'tag_' + id
        }).appendTo($('ul.list-group'));
    }

    /**
     * Salva uma tag existente referenciando o evento.
     */
    function salvar(id, descricao) {
        if (id > 0) {
            loading.show();
            var params = {
                id_evento: $('#id_evento').val(),
                id: id,
                format: 'json'
            };
            var url = '/evento/ajax-salvar-tag';
            $.getJSON(url, params, function(json) {
                if (json.ok) {
                    alertify.success(json.msg);
                    appendToUl(id, descricao);
                    termo.val('').focus();
                } else if (json.error) {
                    alertify.error(json.error);
                    termo.select();
                }
            }).complete(function() {
                loading.hide();
            });
        }
    }

    /**
     * Cria uma nova tag inserindo na tabela tags.
     */
    function criar(descricao) {
        if (descricao !== '') {
            loading.show();
            var params = {
                descricao:  descricao,
                format: 'json'
            };
            var url = '/evento/ajax-criar-tag';
            $.getJSON(url, params, function(json) {
                if (json.ok) {
                    salvar(json.id, descricao);
                } else if (json.error) {
                    alertify.error(json.error);
                    termo.select();
                }
            }).complete(function() {
                loading.hide();
            });
        }
    }

    function deletar(id) {
        if (id > 0) {
            loading.show();

            var url = '/evento/ajax-deletar-tag';
            var params = {
                id: id,
                id_evento: $('#id_evento').val(),
                format: 'json'
            };
            $.getJSON(url, params, function(json) {
                if (json.ok) {
                    alertify.success(json.msg);
                    $('#tag_' + id).remove();
                    termo.select();
                } else if (json.error) {
                    alertify.error(json.error);
                    termo.select();
                }
            }).complete(function() {
                loading.hide();
                if ($('ul.list-group li').length === 0) {
                    $('div.panel-body').css('display', 'block');
                }
            });
        }
    }

    $('#termo').keyup(function(event) {
        if ($(this).val().length === 0) {
            $('#criar-tag').hide();
            return false;
        }

        switch (event.keyCode) {
            case 27: // ESC
                if ($(this).val().length !== 0) {
                    $('#criar-tag').show();
                }
                return false;
            default:
                return true;
        }
    });

    $(document).delegate('#criar-tag', 'click', function() {
        criar(termo.val());
        $('#criar-tag').hide();
    });

    $(document).delegate('a.remover', 'click', function() {
        deletar($(this).attr('data-id'));
    });

    $('#termo').autocomplete({
        search: function( /*event, ui*/ ) {
            loading.show();
        },
        source: function( request, response ) {

            $.ajax({
                url: '/evento/ajax-buscar-tags/',
                data: {
                    termo: request.term,
                    format: 'json'
                },
                success: function( result ) {
                    $('#criar-tag').hide();
                    if (result.itens.length > 0) {
                        response($.map(result.itens, function(item) {
                            return {
                                id: item.id,
                                label: item.text,
                                value: item.text
                            };
                        })); // end of response
                    } else {
                        $('#criar-tag').show();
                        termo.autocomplete('close');
                    }
                } // end of success
            }).complete(function () {
                loading.hide();
            }); // end of ajax
        }, // end of source
        minLength: 1,
        select: function( event, ui ) {
            salvar(ui.item.id, ui.item.value);
        }
    });

});
