autofocusResourceForm = ->
  return unless $('form.resource-form').length
  $('form.resource-form').find('input, select').filter(':visible:not([readonly])')[0]?.focus()
  NullifiableInput.setup('form.resource-form input', false)

newCollaboratorForm = ->
  return unless $('#new_collaborator').length
  $('#new_collaborator input.radio_buttons').on 'change', (e) ->
    $('#new_collaborator input.check_boxes').attr(disabled: @value is 'true', checked: @value is false)

$ ->
  autofocusResourceForm()
  newCollaboratorForm()
