
$(function () {
    $('#definirsenha').parsley().subscribe('parsley:form:validated', function (formInstance) {
        if (formInstance.isValid()) {
            $('#submit').val(_('Loading...')).addClass('disabled');
        }
	});
});
