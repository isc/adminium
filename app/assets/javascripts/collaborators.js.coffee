$ ->
  $('#new_collaborator').live 'ajax:before', ->
    input = $(this).find('input[type=email]')
    $('<li>').text(input.val()).appendTo('#collaborators')
  $('#new_collaborator').live 'ajax:complete', ->
    $(this).find('input[type=email]').val('')
  $('#collaborators a').live 'ajax:complete', ->
    $(this).closest('li').remove()

  $("input[name=all_actions]").click ->
    scope = $(this).closest("tr").find("input:not(:first)")
    if (this.checked)
      scope.attr('checked', 'checked')
    else
      scope.removeAttr('checked')

  column_check = (index) ->
    ->
      checked = $("table").find("tr:first-child th:nth-child(#{index+2}) input[type=checkbox]").get(0).checked
      scope = $("table").find("td:nth-child(#{index+3}) input[type=checkbox]")
      if checked
        scope.attr('checked', 'checked')
      else
        scope.removeAttr('checked')

  for action, index in ["create", "read", "update", "delete"]
    $("input[name=#{action}_all]").click column_check(index)
