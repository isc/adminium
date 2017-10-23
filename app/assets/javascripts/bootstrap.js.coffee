# https://select2.org/troubleshooting/common-problems#select2-does-not-function-properly-when-i-use-it-inside-a-bootst
$.fn.modal.Constructor.prototype.enforceFocus = ->

adminiumSelect2Matcher = (params, data) ->
  return data unless params.term and params.term isnt ''
  r = new RegExp(params.term.split('').join('.*'), 'i')
  if data.children
    newData = $.extend({}, data, true)
    newData.children = (child for child in data.children when child.text.match(r))
    if newData.children.length then newData else null
  else
    if data.text.match(r) then data else null

window.initDatepickers = -> $('input[type=date]').datepicker autoclose: true, format: 'yyyy-mm-dd' unless Modernizr.inputtypes['date']
$ ->
  $('span[rel=tooltip], button[rel=tooltip], a[rel*=tooltip], i[rel=tooltip]').tooltip(container: 'body')
  $("a.text-more, span.text-more, i.text-more").popover(trigger: 'hover', html: true)
  initDatepickers()
  sh_highlightDocument()

$.fn.select2.defaults.set('theme', 'bootstrap')
$.fn.select2.defaults.set('width', '') # https://github.com/select2/select2/issues/3278
$.fn.select2.defaults.set('matcher', adminiumSelect2Matcher)
$('select.select2').select2()
