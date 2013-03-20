makeSortable = (selector) ->
  return unless (table = $(selector)).length
  table.on 'click', 'th', (e) ->
    order = $(e.currentTarget).data('order') or 'desc'
    orderMul = if order is 'desc' then -1 else 1
    $(e.currentTarget).data('order', if order is 'desc' then 'asc' else 'desc')
    index = $(e.currentTarget).prevAll().length
    rows = (tr.cloneNode(true) for tr in table.find('tbody tr'))
    rows.sort (e1, e2) ->
      [td1, td2] = [$(e1).find('td').eq(index), $(e2).find('td').eq(index)]
      if index is 1
        [v1, v2] = [td1.text(), td2.text()]
      else
        [v1, v2] = [Number(td1.data('value')), Number(td2.data('value'))]
      if v1 > v2
        -1 * orderMul
      else
        1 * orderMul
    table.find('tbody').empty()
    table.find('tbody').get(0).appendChild(row) for row in rows

number_with_delimiter = (number, delimiter=',') ->
  number = "#{number}"
  delimiter = delimiter
  split = number.split('.')
  split[0] = split[0].replace /(\d)(?=(\d\d\d)+(?!\d))/g, "$1#{delimiter}"
  split.join('.')

loadTablesCount = ->
  tables = []
  for td in $("td[data-status=loading]")
    table_name = $(td).data('table-name')
    tables.push table_name
  if tables.length > 0
    $.ajax
      url: 'dashboard/tables_count'
      method: 'GET'
      data: {tables: tables}
      success: (data) ->
        for table_name, value of data
          td = $("td[data-table-name=#{table_name}]")
          td.text(number_with_delimiter(value)).attr('data-status', 'loaded').attr('data-value', value)
          total = Number($("tfoot td.total_table_count").attr('data-value')) + value
          $("tfoot td.total_table_count").text(number_with_delimiter(total)).attr('data-value', total)
        loadTablesCount()
$ ->
  makeSortable '.sortable'
  loadTablesCount()