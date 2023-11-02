const setupValidations = () => {
  const pane = $('#validations_pane')
  pane.on('click', '.remove', function(){
    index = $(this).closest('tr').index()
    $(this).closest('tr').remove()
    input = pane.find('.params input').eq(index * 2)
    input.add(input.next()).remove()
  })
  pane.find('button.btn').click(() => {
    const validator = pane.find('select:eq(0) option:selected')
    const column_name = pane.find('select:eq(1) option:selected')
    const tr = $('<tr>').appendTo(pane.find('table'))
    $('<td>').text(validator.text()).appendTo(tr)
    $('<td>').text(column_name.text()).appendTo(tr)
    $('<td>').append($('<i class="fa fa-minus-circle remove">')).appendTo(tr)
    pane.find('.params').append($('<input type="hidden">').attr({ name: "validations[][validator]", value: validator.val() }))
    pane.find('.params').append($('<input type="hidden">').attr({ name: "validations[][column_name]", value: column_name.val() }))
    return false
  })
}

const masterCheckboxes = () => {
  $('.master_checkbox input').on('change', function(){
    $(this).closest('ul').next().find('input[type="checkbox"]').prop('checked', $(this).prop('checked'))
  })
}

$(() => {
  $('#welcome-modal').modal()
  $('.sortable').sortable()
  setupValidations()
  masterCheckboxes()
})
