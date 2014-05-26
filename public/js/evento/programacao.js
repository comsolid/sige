$(function () {

    // padrão: modo normal
    modoNormal();

    $("#modo-normal").click(function () {
        modoNormal();
    });

    $("#modo-impressao").click(function () {
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

    moment.lang('pt-br');
    var intervalID = null;
    $("#auto-scroll").change(function() {
        if ($(this).is(':checked')) {
            scrollToDate();
            intervalID = setInterval(scrollToDate, 10000);
        } else {
            if (intervalID !== null) {
                clearInterval(intervalID);
                intervalID = null;
            }
        }
    });
    
    function scrollToDate() {
        var dataHoraAtual = moment();
        var dia_mes = dataHoraAtual.format('DDMM');
        var eventos = $("." + dia_mes);
        var scrollTo = null; // element to scroll to
        $.each(eventos, function (idx, el) {
            if (idx === 0) {
                scrollTo = el;
            }

            var data = $(el).attr('data-data');
            var hora = $(el).attr('data-hora');
            var data_hora = moment(data + " " + hora, 'DD/MM/YYYY HH:mm:ss');
            if (dataHoraAtual.hour() === data_hora.hour()) {
                $(el).find('.acc-evento .header3').addClass('header3-orange');
            } else {
                $(el).find('.acc-evento .header3').removeClass('header3-orange');
            }
        });
        if (scrollTo != null) {
            $('html, body').animate({
                scrollTop: $(scrollTo).offset().top
            }, 2000);
        }
    }
});