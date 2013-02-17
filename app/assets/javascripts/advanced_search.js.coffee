class AdvancedSearch

  unary_operators: ['null', 'not_null', 'present', 'blank', 'is_true', 'is_false', 'today', 'yesterday', 'this_week', 'last_week']

  constructor: ->
    $('table.filters span.btn').live 'click', ->
      $(this).parents('tr').remove()
    selects = $('table.filters td.operators select')
    selects.live 'change', @selectedOperator
    for select in selects
      @updateFilterForm $(select)
    $("#new_filter").bind 'change', (event) =>
      column_name = $('#new_filter option:selected').val()
      table = $('#new_filter').attr('data-table')
      $('#new_filter').val('')
      $.get "/settings/#{table}?column_name=#{column_name}", (resp) =>
        filterDiv = $("<tr>").append(resp).appendTo($(".filters"))
        selectFilter = filterDiv.find('td.operators select')
        @updateFilterForm(selectFilter)
        $('.datepicker').datepicker onClose: (dateText, inst) ->
          $("##{inst.id}_1i").val(inst.selectedYear)
          $("##{inst.id}_2i").val(inst.selectedMonth + 1)
          $("##{inst.id}_3i").val(inst.selectedDay)

  selectedOperator: (evt) =>
    @updateFilterForm $(evt.currentTarget)

  updateFilterForm: (select) =>
    operator = select.val()
    window.select =select
    window.operand = select.parents('tr').find('.operand')
    visibility = @unary_operators.indexOf(operator) is -1
    operand.toggle(visibility)
    type = if operand.data('type') is 'integer' and operator isnt 'IN'
      'number'
    else
      'text'
    operand.get(0).type = type

$ ->
  new AdvancedSearch()