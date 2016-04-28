autofocusResourceForm = ->
  return unless $('form.resource-form').length
  $('form.resource-form').find('input, select').filter(':visible:not([readonly])')[0]?.focus()
  NullifiableInput.setup('form.resource-form input, form.resource-form textarea', false)

newCollaboratorForm = ->
  return unless $('#new_collaborator').length
  $('#new_collaborator input.radio_buttons').on 'change', (e) ->
    $('#new_collaborator input.check_boxes').attr(disabled: @value is 'true', checked: @value is false)

hstoreInput = ->
  $(document).on 'click', '.hstore-row .btn', ->
    row = $(@).closest('.hstore-row')
    row.next().find('input, a.btn').get(0).focus()
    row.remove()
  $(document).on 'click', '.hstore-new-row .btn', ->
    $('.hstore-row.hidden').first().clone().insertBefore('.hstore-new-row').removeClass('hidden')
    .find('input').val('').get(0).focus()
    false

$ ->
  autofocusResourceForm()
  newCollaboratorForm()
  hstoreInput()
