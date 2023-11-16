const addClause = (clauseType, elt) => {
  td = $(elt.currentTarget).closest('td')
  updatedHref = location.href
  updatedHref += location.search ? '&' : '?'
  value = td.data('raw-value')
  if (value === undefined) value = 'null'
  column = td.data('column-name')
  foreignKey = td.closest('table').find('th').eq(td.index()).data('foreign-key')
  if (foreignKey) column = `${foreignKey}.${column}`
  updatedHref += `${clauseType}[${column}]=${value}`
  location.href = updatedHref
}

const setupCellFilter = elt => {
  td = $(elt.currentTarget)
  if (!td.find('i.fa-indent').length) {
    $(
      '<i class="fa fa-indent cell-action"" title="Select rows with this value">'
    ).appendTo(td)
    $(
      '<i class="fa fa-outdent cell-action"" title="Exclude rows with this value">'
    ).appendTo(td)
  }
}

$('.items-list')
  .on('mouseover', 'td[data-raw-value], td.nilclass', setupCellFilter)
  .on('click', 'td i.fa-indent', elt => addClause('where', elt))
  .on('click', 'td i.fa-outdent', elt => addClause('exclude', elt))
