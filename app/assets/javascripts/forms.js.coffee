autofocusResourceForm = ->
  return unless $('form.resource-form').length
  $('form.resource-form').find('input, select').filter(':visible')[0]?.focus()
$ autofocusResourceForm
