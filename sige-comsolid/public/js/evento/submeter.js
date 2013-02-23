/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

$(function() {
   $("#nome_evento").focus();

   $('#id_tipo_evento').qtip({
      content: {
         text: "<ul style='list-style-type: square;padding-left: 15px;font-size: 13px;'>" +
               "<li><b>Palestras</b> são de até 1 hora de duração.</li>" +
               "<li><b>Oficinas</b> são realizadas somente num dia, podendo ter de 2 a " +
                  "3 horas de duração.</li>" +
               "<li><b>Minicursos</b> são realizados em vários dias, podendo ter de 2 a " +
                  "3 horas de duração por dia.</li></ul>",
          title: "Sobre o tempo de duração"
      },
      position: {
         my: 'left center',
         at: 'center right'
      },
      show: 'focus',
      hide: 'blur',
      style: {
         width: 400,
         classes: 'qtip qtip-default qtip-shadow qtip-bootstrap'
      }
   });
});