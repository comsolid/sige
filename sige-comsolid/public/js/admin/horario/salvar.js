/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

$(function() {
   $("#hora_inicio").change(function() {
      var index = $("#hora_inicio option:selected").index();
      $("#hora_fim option:eq(" + index + ")").attr('selected', 'selected');
   });
});