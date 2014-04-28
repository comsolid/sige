$(function () {

    var note = $('#note'),
        // data do evento
        ts = new Date(2014, 11, 18),
        itsTime = true,
        // mude para o nome do seu evento
        MSG_EVENTO = _("to the ESL I!");

    if ((new Date()) > ts) {
        itsTime = false;
    }

    $('#countdown').countdown({
        timestamp: ts,
        callback: function (days, hours, minutes, seconds) {

            var message = "";
            var s_days = Jed.sprintf(i18n.ngettext("one day", "%d days", days), days) + ", ";
            message += s_days;
            var s_hours = Jed.sprintf(i18n.ngettext("one hour", "%d hours", hours), hours) + ", ";
            message += s_hours;
            var s_minutes = Jed.sprintf(i18n.ngettext("one minute", "%d minutes", minutes), minutes) + " and ";
            message += s_minutes;
            var s_seconds = Jed.sprintf(i18n.ngettext("one second", _("%d seconds"), seconds), seconds) + "<br/>";
            message += s_seconds;

            if (itsTime) {
                message += MSG_EVENTO;
            } else {
                message = _("It's starts!");
            }
            note.html(message);
        }
    });
});