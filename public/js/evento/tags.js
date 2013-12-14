
$(function() {
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
   
   $(document).delegate('.select2-search-choice-close', 'click', function() {
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
   if ($("ul.select2-choices li").length === 0) {
      $("ul.select2-choices").html("");
   }
   
   $("<li>", {
      html: "<div>" + descricao + "</div>" +
              "<a href=\"#\" data-id=\"" + id + "\" onclick=\"return false;\"" +
              " class=\"select2-search-choice-close\" tabindex=\"-1\"></a>",
      class: "select2-search-choice",
      id: "tag_" + id
   }).appendTo($("ul.select2-choices"));
}

function salvar(id, descricao) {
   if (id > 0) {
      $("#loading").show();
      var id_evento = $("#id_evento").val();
      var url = "/evento/ajax-salvar-tag/id/" + id + "/id_evento/" + id_evento;
      $.getJSON(url, function(json) {
         if (json.ok) {
            mostrarMensagem("div.success", json.msg);
            appendToUl(id, descricao);
            $("#termo").val("");
            $("#termo").focus();
         } else if (json.erro !== null) {
            mostrarMensagem("div.error", json.erro);
            $("#termo").select();
         }
      }).complete(function() {
         $("#loading").hide();
      });
   }
}

function criar(descricao) {
   if (descricao !== "") {
      $("#loading").show();
      var url = "/evento/ajax-criar-tag/descricao/" + descricao;
      $.getJSON(url, function(json) {
         if (json.ok) {
            salvar(json.id, descricao);
         } else if (json.erro !== null) {
            mostrarMensagem("div.error", json.erro);
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
            mostrarMensagem("div.success", json.msg);
            $("#tag_" + id).remove();
            $("#termo").select();
         } else if (json.erro !== null) {
            mostrarMensagem("div.error", json.erro);
            $("#termo").select();
         }
      }).complete(function() {
         $("#loading").hide();
      });
   }
}

function mostrarMensagem( id, msg ) {
   var aux = (msg != null) ? msg : "Erro desconhecido.";
   $(id).html( aux ).show( "blind", 500, esconderMensagem(id) );
}

function esconderMensagem(id) {
   setTimeout(function() {
      $( id + ":visible" ).fadeOut();
   }, 3000 );
}