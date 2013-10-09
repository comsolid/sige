$(function(){

   var note = $('#note'),
      ts = new Date(2013, 10, 5),
      newYear = true;

   if((new Date()) > ts){
      newYear = false;
   }

   $('#countdown').countdown({
      timestamp   : ts,
      callback    : function(days, hours, minutes, seconds){

         var message = "";
         message += days + " dia" + ( days==1 ? '':'s' ) + ", ";
         message += hours + " hora" + ( hours==1 ? '':'s' ) + ", ";
         message += minutes + " minuto" + ( minutes==1 ? '':'s' ) + " e ";
         message += seconds + " segundo" + ( seconds==1 ? '':'s' ) + " <br />";

         if(newYear){
            message += "para o COMSOLiD 6!";
         } else {
            message = "Começou!";
         }
         note.html(message);
      }
   });
});