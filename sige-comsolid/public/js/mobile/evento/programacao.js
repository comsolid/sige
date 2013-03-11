
$(function() {
   
   $(".dia:first").show();
   $("ul li:first a").addClass("ui-btn-active");
   
   $("ul li a").click(function() {
      $(".dia").hide();
      var id = $(this).attr("data-id");
      $("#" + id).show();
   });
   
});
