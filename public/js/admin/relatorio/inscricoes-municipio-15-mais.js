
$(function() {
   
   gerarRelatorio();
   
   $("#reload").click(function() {
      $(".icon-refresh").addClass("icon-spin");
      $("#bar-chart").html("");
      gerarRelatorio();
   });
});

function gerarRelatorio() {
   var url = "/admin/relatorios/ajax-inscricoes-municipio-15-mais";
   $.getJSON(url, function(json) {
		console.log(json);
      if (json.ok) {
         Morris.Bar({
            element: 'bar-chart',
            barColors: ['#4da74d', '#0b62a4'],
            data: json.array,
            xkey: 'municipio',
            ykeys: ['confirmados', 'num'],
            labels: ['Num. confir.', 'Num. insc.'],
            stacked: true
         });
      } else if (json.erro != null) {
         mostrarMensagem("div.error", json.erro);
      }
   }).complete(function() {
      $(".icon-refresh").removeClass("icon-spin");
   });
}
