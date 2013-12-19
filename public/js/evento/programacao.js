
$(function() {
   
   // padrão: modo normal
   modoNormal();
   
   $("#modo-normal").click(function() {
      modoNormal();
   });
   
   $("#modo-impressao").click(function() {
      modoImpressao();
   });
   
   function modoNormal() {
      $(".acc-evento").accordion({
         collapsible: true,
         header: 'div.header3',
         active: false
      });
   }
   
   function modoImpressao() {
      $(".acc-evento").accordion("destroy");
   }
});