
$(function () {
    $('#login').parsley().subscribe('parsley:form:validated', function (formInstance) {
        if (formInstance.isValid()) {
            $('#submit').val('Entrando...').addClass('disabled');
        }
	});
});
