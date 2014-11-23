
$(function() {
    $('a.close[data-toggle="tooltip"]').tooltip();
    $("#loading").hide();
    $("#termo").select();
   
    $("#termo").keyup(function(event) {
        if ($(this).val().length === 0) {
            $("#criar-tag").hide();
            return false;
        }
      
        switch (event.keyCode) {
            case 27: // ESC
                if ($(this).val().length !== 0) {
                    $("#criar-tag").show();
                }
                return false;
            default:
                return true;
        }
    });
   
    $(document).delegate('#criar-tag', 'click', function() {
        criar($("#termo").val());
        $("#criar-tag").hide();
    });
   
    $(document).delegate('a.remover', 'click', function() {
        deletar($(this).attr("data-id"));
    });
   
    $("#termo").autocomplete({
        search: function( event, ui ) {
            $("#loading").show();
        },
        source: function( request, response ) {
         
            $.ajax({
                url: "/evento/ajax-buscar-tags/termo/" + request.term,
                contentType: "application/x-www-form-urlencoded; charset=utf-8;",
                success: function( result ) {
                    $("#criar-tag").hide();
                    if (result.itens.length > 0) {
                        response($.map(result.itens, function(item) {
                            return {
                                id: item.id,
                                label: item.text,
                                value: item.text
                            };
                        })); // end of response
                    } else {
                        $("#criar-tag").show();
                        $("#termo").autocomplete('close');
                    }
                } // end of success
            }).complete(function () {
                $("#loading").hide();
            }); // end of ajax
        }, // end of source
        minLength: 1,
        select: function( event, ui ) {
            salvar(ui.item.id, ui.item.value);
        }
    });
   
});

function appendToUl(id, descricao) {
    if ($("ul.list-group li").length === 0) {
        $("ul.list-group").html("");
    }
    
    /**
     * <li class="list-group-item" id="tag_<?= $tag['id'] ?>">
            <?= $tag['descricao'] ?>
            <a href="#" onclick="return false;"
                class="close remover pull-right"
                data-id="<?= $tag['id'] ?>"
                data-toggle="tooltip" data-placement="top"
                title="<?php echo $this->translate("Remove"); ?>">
               <span aria-hidden="true">&times;</span>
               <span class="sr-only">Close</span>
            </a>
        </li>
     */
   
    $("<li>", {
        html: descricao +
              '<a href="#" onclick="return false;" ' +
              'class="close remover pull-right" ' +
              sprintf('data-id="%d" data-toggle="tooltip" data-placement="top" ', id) +
              sprintf('title="%s">', _('Remove')) +
              '<span aria-hidden="true">&times;</span><span class="sr-only">Close</span></a>',
        class: "list-group-item",
        id: "tag_" + id
    }).appendTo($("ul.list-group"));
}

/**
 * Salva uma tag existente referenciando o evento.
 */
function salvar(id, descricao) {
    if (id > 0) {
        $("#loading").show();
        var id_evento = $("#id_evento").val();
        var url = "/evento/ajax-salvar-tag/id/" + id + "/id_evento/" + id_evento;
        $.getJSON(url, function(json) {
            if (json.ok) {
                //mostrarMensagem("div.success", json.msg);
                alertify.success(json.msg);
                appendToUl(id, descricao);
                $("#termo").val("");
                $("#termo").focus();
            } else if (json.error) {
                //mostrarMensagem("div.error", json.erro);
                alertify.error(json.error);
                $("#termo").select();
            }
        }).complete(function() {
            $("#loading").hide();
        });
    }
}

/**
 * Cria uma nova tag inserindo na tabela tags.
 */
function criar(descricao) {
    if (descricao !== "") {
        $("#loading").show();
        var url = "/evento/ajax-criar-tag/descricao/" + descricao;
        $.getJSON(url, function(json) {
            if (json.ok) {
                salvar(json.id, descricao);
            } else if (json.error) {
                alertify.error(json.error);
                $("#termo").select();
            }
        }).complete(function() {
            $("#loading").hide();
        });
    }
}

function deletar(id) {
    if (id > 0) {
        $("#loading").show();
        var id_evento = $("#id_evento").val();
        var url = "/evento/ajax-deletar-tag/id/" + id + "/id_evento/" + id_evento;
        $.getJSON(url, function(json) {
            if (json.ok) {
                alertify.success(json.msg);
                $("#tag_" + id).remove();
                $("#termo").select();
            } else if (json.error) {
                alertify.error(json.error);
                $("#termo").select();
            }
        }).complete(function() {
            $("#loading").hide();
        });
    }
}
