$ ->
  $("#welcome-modal").modal()
  $('ul.sortable').sortable()
  $('table.filters span.btn').live 'click', ->
    $(this).parents('tr').remove()
  $("#new_filter").bind 'change', (event) ->
    column_name = $('#new_filter option:selected').val()
    table = $('#new_filter').attr('data-table')
    $('#new_filter').val('')
    $.get "/settings/#{table}?column_name=#{column_name}", (resp) ->
      $("<tr>").append(resp).appendTo($(".filters"))
      $('.datepicker').datepicker onClose: (dateText, inst) ->
        $("##{inst.id}_1i").val(inst.selectedYear)
        $("##{inst.id}_2i").val(inst.selectedMonth + 1)
        $("##{inst.id}_3i").val(inst.selectedDay)
  setupValidations()
  setupSearchDeletion()

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

setupSearchDeletion = ->
  $('#manage_searches .btn-danger').bind 'ajax:before', ->
    search_name = $(this).closest('tr').find('td').eq(0).text()
    link = link for link in $('.dropdown-searches a') when $(link).text() is search_name
    $(link).closest('li').remove()
    $(this).closest('tr').remove()
