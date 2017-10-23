class AdvancedSearch

  unary_operators: ['null', 'not_null', 'present', 'blank', 'is_true', 'is_false', 'today', 'yesterday',
                    'this_week', 'last_week']

  constructor: ->
    $('table.filters').on 'click', 'span.btn', -> $(this).parents('tr').remove()
    $('table.filters').on 'change', 'td.operators select', (evt) => @updateFilterForm $(evt.currentTarget)
    @updateFilterForm $(select) for select in $('table.filters td.operators select')
    $("#new_filter").on 'change', (event) =>
      column_name = event.target.value
      return unless column_name
      $('#new_filter').val('').trigger('change')
      optgroup = $(event.target).find(':selected').closest('optgroup')
      table = $('#new_filter').data('table')
      $.get "/settings/#{table}", {column_name, assoc: optgroup.data('name')}, (resp) =>
        filterDiv = $('<tr>').append(resp).appendTo($('.filters'))
        selectFilter = filterDiv.find('td.operators select').focus()
        @updateFilterForm selectFilter
        initDatepickers()

  updateFilterForm: (select) =>
    operator = select.val()
    operand = select.parents('tr').find('.operand')
    visibility = @unary_operators.indexOf(operator) is -1
    operand.toggle(visibility).attr('required', visibility)
    type = if operand.data('type') is 'integer' and operator isnt 'IN'
      operand.get(0).step = 'any' if operand.data('original-type') isnt 'integer'
      'number'
    else if operand.data('type') is 'date'
      'date'
    else
      'text'
    operand.get(0).type = type

$ -> new AdvancedSearch()
