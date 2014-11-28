
$(function() {
	$('input#email').focus();

	$('.select2').select2();
	$('.date').mask('99/99/9999');

	$('#cpf').mask('999.999.999-99');
	$('#telefone').mask('(99) 9999-9999');

    /*$('#submit').click(function () {
		$( '#criar_pessoa' ).parsley( 'validate' );
		var valid = $( '#criar_pessoa' ).parsley( 'isValid' );
		if (valid) {
			$(this).val('Enviando...').addClass('disabled');
		}
    });*/

	$('#criar_pessoa').parsley().subscribe('parsley:form:validated', function (formInstance) {
        if (formInstance.isValid()) {
            $('#submit').val('Enviando...').addClass('disabled');
        }
	});
});
