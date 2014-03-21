$ ->
  $("#welcome-modal").modal()
  $('ul.sortable').sortable()
  setupValidations()
  setupDbUrlPresence()
  showModalOnLoad()
  masterCheckboxes()

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

showModalOnLoad = ->
  $(".modal[data-open-on-load]").eq(0).modal('show')

setupDbUrlPresence = ->
  return unless $('.heroku-connection-instructions').length
  setInterval ->
    $.get '/account/db_url_presence', (data) ->
      window.location = '/dashboard?step=done' if data
  , 6000

masterCheckboxes = ->
  $('.master_checkbox input').on 'change', ->
    $(this).closest('ul').next().find('input[type="checkbox"]').prop('checked', $(this).prop('checked'))
