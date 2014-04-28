
var i18n = (function () {
    var jed;

    return {
        init: function (locale) {
            jed = new Jed({
                "domain": "messages",
                "locale_data": locale_data
            });
        },
        _: function (msgid) {
            if (typeof(jed.gettext) === "function") {
                return jed.gettext(msgid);
            } else {
                console.log("locale not initialized.");
            }
        },
        ngettext: function(singular_key, plural_key, value) {
            if (typeof(jed.ngettext) === "function") {
                return jed.ngettext(singular_key, plural_key, value);
            } else {
                console.log("locale not initialized.");
            }
        }
    };
})();

i18n.init();
// make _() function public
window._ = i18n._;