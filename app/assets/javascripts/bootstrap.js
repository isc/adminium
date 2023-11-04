// https://select2.org/troubleshooting/common-problems#select2-does-not-function-properly-when-i-use-it-inside-a-bootst
$.fn.modal.Constructor.prototype.enforceFocus = () => {}

const adminiumSelect2Matcher = (params, data) => {
  if (!params.term) return data
  const r = new RegExp(params.term.split('').join('.*'), 'i')
  if (data.children) {
    const newData = $.extend({}, data, true)
    newData.children = data.children.filter(child => child.text.match(r))
    return newData.children.length ? newData : null
  }
  return data.text.match(r) ? data : null
}

$(() => {
  $(
    'span[rel=tooltip], button[rel=tooltip], a[rel*=tooltip], i[rel=tooltip]'
  ).tooltip({ container: 'body' })
  $('a.text-more, span.text-more, i.text-more').popover({
    trigger: 'hover',
    html: true
  })
  sh_highlightDocument()
})

$.fn.select2.defaults.set('theme', 'bootstrap')
$.fn.select2.defaults.set('width', '') // https://github.com/select2/select2/issues/3278
$.fn.select2.defaults.set('matcher', adminiumSelect2Matcher)
$('select.select2').select2()
