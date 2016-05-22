class CellFilters
  constructor: ->
    @currentTableName = $('.items-list').data('table')
    $('.items-list')
      .on('mouseover', 'td[data-raw-value], td.nilclass', @setupCellFilter)
      .on('click', 'td i.fa-indent', @addWhereClause)
      .on('click', 'td i.fa-outdent', @addExcludeClause)

  setupCellFilter: (elt) =>
    td = $(elt.currentTarget)
    if not td.find('i.fa-indent').length
      $('<i class="fa fa-indent cell-action"" title="Select rows with this value">').appendTo(td)
      $('<i class="fa fa-outdent cell-action"" title="Exclude rows with this value">').appendTo(td)

  addWhereClause: (elt) =>
    @addClause 'where', elt

  addExcludeClause: (elt) =>
    @addClause 'exclude', elt

  addClause: (clauseType, elt) =>
    td = $(elt.currentTarget).closest('td')
    updatedHref = location.href
    updatedHref += if location.search then '&' else '?'
    value = td.data('raw-value')
    value = 'null' if value is undefined
    column = td.data('column-name')
    tableName = td.closest('table').find('th').eq(td.index()).data('table-name')
    column = "#{tableName}.#{column}" if @currentTableName isnt tableName
    updatedHref += "#{clauseType}[#{column}]=#{value}"
    location.href = updatedHref

$ -> new CellFilters()
