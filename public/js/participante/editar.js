
$(function() {
	$("input#nome").focus();

	$("select.select2").select2({
		width: '280px'
	});
   	$("#nascimento.date").mask('99/99/9999');

	$("#cpf").mask('999.999.999-99');
	$("#telefone").mask('(99) 9999-9999');

   //$("#tabs").tabs();
});
