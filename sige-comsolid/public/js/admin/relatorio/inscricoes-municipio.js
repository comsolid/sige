/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

$(function() {
   
   gerarRelatorio();
   
   $("#reload").click(function() {
      $(".icon-refresh").addClass("icon-spin");
      $("#bar-chart").html("");
      gerarRelatorio();
   });
});

function gerarRelatorio() {
   var url = "/admin/relatorios/ajax-inscricoes-municipio";
   $.getJSON(url, function(json) {
      if (json.ok) {
         Morris.Bar({
            element: 'bar-chart',
            data: json.array,
            xkey: 'municipio',
            ykeys: ['num'],
            labels: ['Num. insc.']
         });
      } else if (json.erro != null) {
         mostrarMensagem("div.error", json.erro);
      }
   }).complete(function() {
      $(".icon-refresh").removeClass("icon-spin");
   });
}