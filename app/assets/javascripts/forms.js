const hstoreInput = () => {
  $(document).on('click', '.hstore-row .btn', function(){
    row = $(this).closest('.hstore-row')
    row.next().find('input, a.btn').get(0).focus()
    row.remove()
  })
  $(document).on('click', '.hstore-new-row .btn', function(){
    parent = $(this).closest('.hstore-edition')
    parent.find('.hstore-row.hidden').first().clone()
      .insertBefore(parent.find('.hstore-new-row')).removeClass('hidden')
      .find('input').val('').get(0).focus()
  })
}

const autofocusResourceForm = () => {
  if (!$('form.resource-form').length) return
  $('form.resource-form').find('input, select').filter(':visible:not([readonly])')[0]?.focus()
  NullifiableInput.setup('form.resource-form input, form.resource-form textarea', false)
}

const newCollaboratorForm = () => {
  if (!$('#new_collaborator').length) return
  $('#new_collaborator input.radio_buttons').on('change', function(){
    $('#new_collaborator input.check_boxes').attr({ disabled: this.value === 'true', checked: this.value === false })
  })
}

$(() => {
  autofocusResourceForm()
  newCollaboratorForm()
  hstoreInput()
})
