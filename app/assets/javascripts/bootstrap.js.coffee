$ ->
  # $(".alert-message").alert()
  # $(".tabs").button()
  # $(".carousel").carousel()
  # $(".dropdown-toggle").dropdown()
  # $(".tab").tab "show"
  # $(".tooltip").tooltip()
  # $(".typeahead").typeahead()
  $('span[rel=tooltip], button[rel=tooltip], a[rel*=tooltip], i[rel=tooltip]').tooltip(container: 'body')
  $("a.text-more, span.text-more, i.text-more").popover(trigger: 'hover')
  $('.datepicker').datepicker
    weekHeader: "Week"
    showWeek: true
    altField: $("#generic_account_4_document_range_1")
    onSelect: (dateText, inst) ->
      $("##{inst.id}_1i").val(inst.selectedYear)
      $("##{inst.id}_2i").val(inst.selectedMonth + 1)
      $("##{inst.id}_3i").val(inst.selectedDay)
  sh_highlightDocument()
$('select.select2').select2()