
$(function () {
    moment.lang('pt-br');
    $('span[data-moment]').each(function(idx, item) {
		var $item = $(item);
		var date = $item.attr('data-moment');
		$item.html(moment(date, 'DD/MM/YYYY HH:mm').fromNow());
	});

    var LOADING_TEXT = '<i class="fa fa-refresh fa-spin"></i>';

    var ajax_user_registration = {
        url: '/admin/dashboard/ajax-user-registration',
        type: 'POST',
        dataType: 'JSON',
        data: {
            format: 'json'
        },
        beforeSend: function () {
            $('#user-registration h3').html(LOADING_TEXT);
        },
        success: function (json) {
            if (json.ok) {
                $('#user-registration h3').html(json.num_participants);
            } else if (json.error) {
                alertify.error(json.error);
                $('#user-registration h3').html(0);
            }
        },
        error: function (jqXHR, textStatus, errorThrown) {
            alertify.error(textStatus + ':' + errorThrown);
            $('#user-registration h3').html('-');
        }
    };

    var ajax_total_events = {
        url: '/admin/dashboard/ajax-total-events',
        type: 'POST',
        dataType: 'JSON',
        data: {
            format: 'json'
        },
        beforeSend: function () {
            $('#total-events h3').html(LOADING_TEXT);
        },
        success: function (json) {
            if (json.ok) {
                $('#total-events h3').html(json.num_events);
            } else if (json.error) {
                alertify.error(json.error);
                $('#total-events h3').html(0);
            }
        },
        error: function (jqXHR, textStatus, errorThrown) {
            alertify.error(textStatus + ':' + errorThrown);
            $('#total-events h3').html('-');
        }
    };

    (function _request() {
        $.ajaxQueue(ajax_user_registration);
        $.ajaxQueue(ajax_total_events);
    })();
    // _request();

    // var weatherTemplate = $('#weather-template').html();
    // var compiledWeatherTemplate = Hogan.compile(weatherTemplate);

    // var forecastTemplate = $('#forecast-template').html();
    // var compiledForecastTemplate = Hogan.compile(forecastTemplate);

    // // $.simpleWeather({
    //     location: 'Maracanaú, CE',
    //     unit: 'c',
    //     success: function(weather) {
    //         var renderedTemplate = compiledWeatherTemplate.render(weather);
    //         $('#weather').html(renderedTemplate);

    //         var forecastHtml = '';
    //         for(var i = 0; i < weather.forecast.length; i++) {
    //             forecastHtml += compiledForecastTemplate.render(weather.forecast[i]);
    //         }
    //         $('#forecast').html(forecastHtml);
    //         $('#weather-loading').css('display', 'none');
    //     },
    //     error: function(error) {
    //         $('#forecast').html('<p>' + error + '</p>');
    //         $('#weather-loading').css('display', 'none');
    //     }
    // });
});
