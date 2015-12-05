window.initDatepickers = -> $('input[type=date]').datepicker autoclose: true, format: 'dd/mm/yyyy' unless Modernizr.inputtypes['date']
$ ->
  $('span[rel=tooltip], button[rel=tooltip], a[rel*=tooltip], i[rel=tooltip]').tooltip(container: 'body')
  $("a.text-more, span.text-more, i.text-more").popover(trigger: 'hover', html: true)
  initDatepickers()
  sh_highlightDocument()
$('select.select2').select2()