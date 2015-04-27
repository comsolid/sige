
$(function () {
    var doc = ace.edit('editor');

    var Mode = require('ace/mode/html').Mode;
    doc.getSession().setMode(new Mode());
    doc.setFontSize('12pt');

    var content = $('#mensagem');
    doc.getSession().setValue(content.val());
    doc.getSession().on('change', function() {
        content.val(doc.getSession().getValue());
    });
});
