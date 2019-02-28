$ ->
  $("input[name=all_actions]").click ->
    scope = $(this).closest("tr").find("input:not(:first)")
    scope.prop('checked', this.checked)

  column_check = (index) ->
    ->
      checked = $("table").find("tr:first-child th:nth-child(#{index+2}) input[type=checkbox]").get(0).checked
      scope = $("table").find("td:nth-child(#{index+3}) input[type=checkbox]")
      scope.prop('checked', checked)

  for action, index in ["create", "read", "update", "delete"]
    $("input[name=#{action}_all]").click column_check(index)
