const unary_operators = [
  'null',
  'not_null',
  'present',
  'blank',
  'is_true',
  'is_false',
  'today',
  'yesterday',
  'this_week',
  'last_week'
]

const updateFilterForm = select => {
  const operator = select.val()
  const operand = select.parents('tr').find('.operand')
  const visibility = unary_operators.indexOf(operator) === -1
  operand.toggle(visibility).attr('required', visibility)
  var type = null
  if (operand.data('type') === 'integer' && operator !== 'IN') {
    if (operand.data('original-type') !== 'integer') operand.get(0).step = 'any'
    type = 'number'
  } else if (operand.data('type') === 'date') type = 'date'
  else type = 'text'
  operand.get(0).type = type
}

const setupAdvancedSearch = () => {
  $('table.filters').on('click', 'span.btn', function () {
    $(this).parents('tr').remove()
  })
  $('table.filters').on('change', 'td.operators select', evt =>
    updateFilterForm($(evt.currentTarget))
  )
  $('table.filters td.operators select').each((_, select) =>
    updateFilterForm($(select))
  )
  $('#new_filter').on('change', event => {
    const column_name = event.target.value
    if (!column_name) return
    const optgroup = $(event.target).find(':selected').closest('optgroup')
    $('#new_filter').val('').trigger('change')
    const table = $('#new_filter').data('table')
    $.get(
      `/settings/${table}`,
      { column_name, assoc: optgroup.data('name') },
      resp => {
        filterDiv = $('<tr>').append(resp).appendTo($('.filters'))
        selectFilter = filterDiv.find('td.operators select').focus()
        updateFilterForm(selectFilter)
      }
    )
  })
}

$(setupAdvancedSearch)
