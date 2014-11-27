
$(function() {
	$("input#email").focus();

	$(".select2").select2();
	$(".date").mask('99/99/9999');

	$("#cpf").mask('999.999.999-99');
	$("#telefone").mask('(99) 9999-9999');
    
    $('#submit').click(function () {
        $(this).val('Enviando...').addClass('disabled');
    });
});
