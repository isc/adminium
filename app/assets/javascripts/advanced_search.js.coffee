class AdvancedSearch

  unary_operators: ['null', 'not_null', 'present', 'blank', 'is_true', 'is_false', 'today', 'yesterday', 'this_week', 'last_week']

  constructor: ->
    $('table.filters').on 'click', 'span.btn', ->
      $(this).parents('tr').remove()
    $('table.filters').on 'change', 'td.operators select', @selectedOperator
    @updateFilterForm $(select) for select in $('table.filters td.operators select')
    $("#new_filter").select2({placeholder: 'Choose a column', matcher: adminiumSelect2Matcher})
    $("#new_filter").bind 'change', (object) =>
      column_name = object.val
      optgroup = $(object.added.element).closest('optgroup')
      assoc = optgroup.data('name')
      table = assoc or $('#new_filter').attr('data-table')
      $('#new_filter').select2("val", "")
      $.get "/settings/#{table}", {column_name: column_name, assoc: assoc}, (resp) =>
        filterDiv = $("<tr>").append(resp).appendTo($(".filters"))
        selectFilter = filterDiv.find('td.operators select').focus()
        @updateFilterForm selectFilter
        initDatepickers()

  selectedOperator: (evt) =>
    @updateFilterForm $(evt.currentTarget)

  updateFilterForm: (select) =>
    operator = select.val()
    operand = select.parents('tr').find('.operand')
    visibility = @unary_operators.indexOf(operator) is -1
    operand.toggle(visibility).attr('required', visibility)
    type = if operand.data('type') is 'integer' and operator isnt 'IN'
      operand.get(0).step = 'any' if operand.data('original-type') isnt 'integer'
      'number'
    else
      'text'
    operand.get(0).type = type
    

$ ->
  new AdvancedSearch()