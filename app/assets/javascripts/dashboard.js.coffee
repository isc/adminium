number_with_delimiter = (number, delimiter=',') ->
  number = "#{number}"
  delimiter = delimiter
  split = number.split('.')
  split[0] = split[0].replace /(\d)(?=(\d\d\d)+(?!\d))/g, "$1#{delimiter}"
  split.join('.')

petprojectLimitationPopup = ->
  $(".black tr.deactivated a").on 'click', (evt) ->
    $("#petprojectLimitationModal").modal("show")
    evt.preventDefault()

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
          datavalue = value
          datavalue = -1 if value == '?'
          datavalue = "#{value}".match(/~(\d+)/)[1] if "#{value}".indexOf('~') == 0
          td.text(number_with_delimiter(value)).attr('data-status', 'loaded').attr('data-value', datavalue)
          if value != "?"
            total = Number($("tfoot td.total_table_count").attr('data-value')) + value
          else
            td.tooltip({title: 'the query to perform this count was too slow'})
          $("tfoot td.total_table_count").text(number_with_delimiter(total)).attr('data-value', total)
        loadTablesCount()
$ ->
  loadTablesCount()
  petprojectLimitationPopup()