$ ->
  $('#settings ul').sortable()
  $("table.filters span.btn").live 'click', ->
    $(this).parents('tr').remove()
  $("#new_filter").bind 'change', (event) ->
    column_name = $("#new_filter option:selected").val()
    table = $("#new_filter").attr("data-table")
    $("#new_filter").val("")
    $.get "/settings/#{table}?column_name=#{column_name}", (resp) ->
      $("<tr>").append(resp).appendTo($(".filters"))
  setupValidations()
  setupEnumValues()

addToHiddenParams = (pane_id, group, params) ->
  div = $("#{pane_id} .params")
  for key, value of params
    div.append($('<input type="hidden">').attr(name:"#{group}[][#{key}]", value:value))

addToTable = (pane_id, cells) ->
  tr = $('<tr>').appendTo("#{pane_id} table")
  $('<td>').text(cell).appendTo tr for cell in cells
  $('<td>').append($('<i>').addClass('icon-remove-sign remove')).appendTo tr

setupRemoval = (pane_id) ->
  $("#{pane_id} .remove").live 'click', ->
    index = $(this).closest('tr').index()
    $(this).closest('tr').remove()
    input = $("#{pane_id} .params input").eq(index * 2)
    input.add(input.next()).remove()

setupValidations = ->
  setupRemoval '#validations_pane'
  $('#validations_pane a.btn').click ->
    validator = $('#validations_pane select:eq(0) option:selected')
    column_name = $('#validations_pane select:eq(1) option:selected')
    addToTable '#validations_pane', [validator.text(), column_name.text()]
    addToHiddenParams '#validations_pane', 'validations', validator:validator.val(), column_name:column_name.val()

setupEnumValues = ->
  setupRemoval '#enum-values_pane'
  $('#enum_value_column_name').change ->
    $.getJSON $(this).data('values-url'), column_name:this.value, (data) ->
      text = ("#{value}: " for value in data).join("\n")
      $('#enum_value_values').val(text)
  $('#enum-values_pane .btn').click ->
    [column, values] = [$('#enum_value_column_name').val(), $('#enum_value_values').val()]
    addToTable '#enum-values_pane', [column, values]
    addToHiddenParams '#enum-values_pane', 'enum_values', column_name:column, values:values
