class TimeCharts
  
  constructor: ->
    @setupTimeChartsCreation()
    @setupGroupingChange()
  
  setupTimeChartsCreation: ->
    $('th i.time-chart').click (e) =>
      @column_name = $(e.currentTarget).closest('.column_header').data('column-name')
      remoteModal '#time-chart', {column: @column_name}, @graphData
      _gaq.push ['_trackPageview', '/time_chart'] if window['_gaq']

  setupGroupingChange: ->
    $(document).on 'change', '#time-chart.modal #grouping', (e) =>
      remoteModal '#time-chart', {column: "#{@column_name}&grouping=#{e.currentTarget.value}"}, @graphData
  
  graphData: (data, container) =>
    data ||= chart_data
    container ||= '#chart_div'
    if data is null
      $(container).text "No data to chart for this grouping value."
      return
    dataTable = new google.visualization.DataTable()
    dataTable.addColumn('string', 'Date')
    dataTable.addColumn('number', 'Count')
    row[0] = String(row[0]) for row in data
    dataTable.addRows data
    wrapper = $(container)
    options = {width: wrapper.parent().css('width'), height:300, colors: ['#7d72bd'], legend: 'none'}
    chart = new google.visualization.ColumnChart(wrapper.get(0))
    chart.draw(dataTable, options)
    $('#time-chart i[rel=tooltip]').tooltip()
  
$ ->
  window.time_charts = new TimeCharts()


window.remoteModal = (selector, params, callback) ->
  $(selector).html($(".loading_modal").html()).modal('show')
  path = $(selector).data('remote-path')
  for key, value of params
    path = path.replace(encodeURIComponent("{#{key}}"), value)
  $.get path, (data) =>
    $(selector).html(data)
    callback() if callback
