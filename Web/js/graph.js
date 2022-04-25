// Produces width of .barChart
$(document).ready(function () {
    $(".graph-bar").each(function () {
      var dataWidth = $(this).data("value");
      $(this).css("width", dataWidth + "%");
    });
  });
  