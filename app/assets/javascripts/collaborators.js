$('input[name=all_actions]').click(function () {
  const scope = $(this).closest('tr').find('input:not(:first)')
  scope.prop('checked', this.checked)
})
const column_check = index => {
  return () => {
    const checked = $('table')
      .find(`tr:first-child th:nth-child(${index + 2}) input[type=checkbox]`)
      .get(0).checked
    const scope = $('table').find(
      `td:nth-child(${index + 3}) input[type=checkbox]`
    )
    scope.prop('checked', checked)
  }
}
;['create', 'read', 'update', 'delete'].forEach((action, index) =>
  $(`input[name=${action}_all]`).click(column_check(index))
)
