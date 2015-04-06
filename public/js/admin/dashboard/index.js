
$(function () {
    $('span[data-moment]').each(function(idx, item) {
		var $item = $(item);
		var date = $item.attr('data-moment');
		$item.html(moment(date, 'DD/MM/YYYY HH:mm').fromNow());
	});

    var LOADING_TEXT = '<i class="fa fa-refresh fa-spin"></i>';

    var ajax_user_registration = {
        url: '/admin/dashboard/ajax-user-registration',
        type: 'POST',
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
        }
    };

    var ajax_total_events = {
        url: '/admin/dashboard/ajax-total-events',
        type: 'POST',
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
        }
    };

    function _request() {
        $.ajaxQueue(ajax_user_registration);
        $.ajaxQueue(ajax_total_events);
    }
    _request();
});
