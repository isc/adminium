jQuery ->
  $(".alert-message").alert()
  $(".tabs").button()
  $(".carousel").carousel()
  $(".dropdown-toggle").dropdown()
  $("a[rel]").popover()
  $(".navbar").scrollspy()
  $(".tab").tab "show"
  $(".tooltip").tooltip()
  $(".typeahead").typeahead()
  $('.datepicker').datepicker onClose: (dateText, inst) ->
    console.log inst
    $("##{inst.id}_1i").val(inst.selectedYear)
    $("##{inst.id}_2i").val(inst.selectedMonth + 1)
    $("##{inst.id}_3i").val(inst.selectedDay)
