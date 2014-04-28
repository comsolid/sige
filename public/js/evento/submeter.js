
$(function() {
   $("#nome_evento").focus();

   $('#id_tipo_evento').qtip({
      content: {
         text: "<ul style='list-style-type: square;padding-left: 15px;font-size: 13px;'>" +
               "<li>" + _("<b>Lectures</b> are up to 1 hour of duration.") + "</li>" +
               "<li>" + _("<b>Workshops</b> are conducted only one day, may be 2-3 hours long.") + "</li>" +
               "<li>" + _("<b>Mini courses</b> are carried out in several days and may have 2-3 hours of time per day.") + "</li></ul>",
          title: _("About the time duration")
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