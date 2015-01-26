$(function () {
    $.datepicker.setDefaults($.datepicker.regional['pt-BR']);

    // or to change the language based on the browser language
    // use the getJqueryUserLanguage function.
});

// this function gets your local locale from the browser
// and always falls back to US English if jQuery doesn't have
// that particular language loaded in jquery-ui-i18n.js
function getJqueryUserLanguage() {
    if (navigator.userLanguage.toLowerCase() === 'en-us') {
        return '';
    } else {
        var l = navigator.userLanguage.toLowerCase().split('-');
        if (l.length === 1) {
            if ($.datepicker.regional[l[0]] !== undefined) {
                return l[0];
            } else {
                return '';
            }
        } else if (l.length > 1) {
            if ($.datepicker.regional[l[0] + '-' + l[1].toUpperCase()] !== undefined) {
                return l[0] + '-' + l[1].toUpperCase();
            } else if ($.datepicker.regional[l[0]] !== undefined) {
                return l[0];
            } else {
                return '';
            }
        } else {
            return '';
        }
    }

    // usage
    $.datepicker.regional[getJqueryUserLanguage()];
}
