$(function(){

    var ts = new Date(2014, 11, 16, 8, 0);
    moment.lang('pt-br');
    $("#countdown").attr('data-date', moment(ts).format('YYYY-MM-DD HH:mm:ss'));

    var countdown = $("#countdown").TimeCircles({
        animation: "ticks",
        count_past_zero: false,
        time: {
            Days: {
                show: true,
                text: _("Days"),
                color: "#feb23c"
            },
            Hours: {
                show: true,
                text: _("Hours"),
                color: "#61c8fa"
            },
            Minutes: {
                show: true,
                text: _("Minutes"),
                color: "#abe15c"
            },
            Seconds: {
                show: true,
                text: _("Seconds"),
                color: "#fd5936"
            }
        }
    });

    var intervalId = setInterval(function () {
        if (countdown.getTime() <= 0) {
            countdown.end().fadeOut(400, function () {
                $('#countdown-title').hide();
                $("#banner-index").show();
            });
            clearInterval(intervalId);
        }
    }, 1000);
});
