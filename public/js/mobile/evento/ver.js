
$(function() {
      
   $(".tab:first").show();
   $("ul li:first a").addClass("ui-btn-active");
   
   $("ul li a").click(function() {
      $(".tab").hide();
      var id = $(this).attr("data-id");
      $("#" + id).show();
   });
   
});

/* button share */
$('<a/>', {
   href: '#panel-share',
   html: "<i class='icon-share-alt'></i> Compartilhar",
   "data-role": 'button',
   class: 'ui-btn-right'
}).appendTo("div[data-role=header]");

$(document).on("pageinit", ".sige-page", function() {
   $(document).on("swipeleft", ".sige-page", function(e) {
      // We check if there is no open panel on the page because otherwise
      // a swipe to close the left panel would also open the right panel (and v.v.).
      // We do this by checking the data that the framework stores on the page element (panel: open).
      if ($.mobile.activePage.jqmData("panel") !== "open") {
         if (e.type === "swipeleft") {
            $("#panel-share").panel("open");
         }
      }
   });
});