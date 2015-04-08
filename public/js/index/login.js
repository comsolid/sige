
$(function () {
    $('#login').parsley().subscribe('parsley:form:validated', function (formInstance) {
        if (formInstance.isValid()) {
            $('#submit').val(_('Loging in...')).addClass('disabled');
        }
	});
});
