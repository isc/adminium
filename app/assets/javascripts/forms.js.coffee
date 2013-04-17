autofocusResourceForm = ->
  return unless $('form.resource-form').length
  $('form.resource-form').find('input, select').filter(':visible:not([readonly])')[0]?.focus()
$ autofocusResourceForm
