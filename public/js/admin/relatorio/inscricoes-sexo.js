/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

$(function() {
   
   gerarRelatorio();
   
   $("#reload").click(function() {
      $(".icon-refresh").addClass("icon-spin");
      $("#donut-chart").html("");
      gerarRelatorio();
   });
});

function gerarRelatorio() {
   var url = "/admin/relatorios/ajax-inscricoes-sexo";
   $.getJSON(url, function(json) {
      if (json.ok) {
         Morris.Donut({
            element: 'donut-chart',
            data: json.array/*,
            formatter: function (x) { return x + "%"}*/
         });
      } else if (json.erro != null) {
         mostrarMensagem("div.error", json.erro);
      }
   }).complete(function() {
      $(".icon-refresh").removeClass("icon-spin");
   });
}