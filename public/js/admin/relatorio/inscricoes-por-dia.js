
$(function() {
   
   gerarRelatorio();
   
   $("#reload").click(function() {
      $(".icon-refresh").addClass("icon-spin");
      $("#line-chart").html("");
      gerarRelatorio();
   });
});

function gerarRelatorio() {
   var url = "/admin/relatorios/ajax-inscricoes-por-dia";
   $.getJSON(url, function(json) {
      if (json.ok) {
         Morris.Line({
            element: 'line-chart',
            data: json.array,
            xkey: 'data',
            ykeys: ['num'],
            labels: ['Num. insc.'],
            dateFormat: function (x) {
               var x = new Date(x);
               return dateFormat(x);
            },
            xLabelFormat: function (x) {
               return dateFormat(x);
            }
         });
      } else if (json.erro != null) {
         mostrarMensagem("div.error", json.erro);
      }
   }).complete(function() {
      $(".icon-refresh").removeClass("icon-spin");
   });
}
