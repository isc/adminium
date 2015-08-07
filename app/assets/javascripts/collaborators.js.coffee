$ ->
  $(document).on 'ajax:before', '#new_collaborator', ->
    input = $(this).find('input[type=email]')
    tr = $('<tr>').addClass("deactivated").appendTo('#collaborators')
    $('<td>').attr("colspan", 3).text(input.val()).appendTo(tr)
  $(document).on 'ajax:complete', '#new_collaborator', ->
    $(this).find('input[type=email]').val('')
  $(document).on 'ajax:complete', 'a.trash_collaborator', ->
    $(this).closest('tr').remove()

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
