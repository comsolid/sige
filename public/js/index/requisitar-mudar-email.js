
$(function () {
    $('#requisitar_mudar_email').parsley().subscribe('parsley:form:validated', function (formInstance) {
        if (formInstance.isValid()) {
            $('#submit').val(_('Sending...')).addClass('disabled');
        }
	});
});
