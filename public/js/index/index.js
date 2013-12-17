$(function(){

   var note = $('#note'),
      // data do evento
      ts = new Date(2013, 11, 18),
      itsTime = true,
      // mude para o nome do seu evento
      MSG_EVENTO = "para o ESL I!";

   if((new Date()) > ts){
      itsTime = false;
   }

   $('#countdown').countdown({
      timestamp   : ts,
      callback    : function(days, hours, minutes, seconds){

         var message = "";
         message += days + " dia" + ( days==1 ? '':'s' ) + ", ";
         message += hours + " hora" + ( hours==1 ? '':'s' ) + ", ";
         message += minutes + " minuto" + ( minutes==1 ? '':'s' ) + " e ";
         message += seconds + " segundo" + ( seconds==1 ? '':'s' ) + " <br />";

         if(itsTime){
            message += MSG_EVENTO;
         } else {
            message = "Começou!";
         }
         note.html(message);
      }
   });
});