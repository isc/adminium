class TimeCharts
  
  constructor: ->
    newScript = document.createElement('script')
    newScript.type = 'text/javascript'
    newScript.src = 'https://www.google.com/jsapi'
    document.getElementsByTagName("head")[0].appendChild(newScript)
    @setupTimeChartsCreation()
    @setupGroupingChange()
    @dataBeforeGoogleChartsLoad = []
    @loadGoogleCharts()
  
  loadGoogleCharts: =>
    if window.hasOwnProperty 'google'
      google.load 'visualization', '1',
        callback: @googleChartsLoadCallback
        packages: ['corechart']
    else
      setTimeout @loadGoogleCharts, 100
  
  googleChartsLoadCallback: =>
    @googleChartsLoaded = true
    @graphData args... for args in @dataBeforeGoogleChartsLoad
  
  setupTimeChartsCreation: ->
    $('th i.time-chart').click (e) =>
      @column_name = $(e.currentTarget).closest('.column_header').data('column-name')
      @type = $(e.currentTarget).data('type')
      remoteModal '#time-chart', {column: @column_name, type: @type}, @graphData
      _gaq.push ['_trackPageview', "/#{@kind}_chart"] if window['_gaq']

  setupGroupingChange: ->
    $(document).on 'change', '#time-chart.modal #grouping', (e) =>
      remoteModal '#time-chart', {column: "#{@column_name}&grouping=#{e.currentTarget.value}", type: @type}, @graphData
  
  statChart: (data, container) =>
    tbody = $(container).html('<table class="table table-condensed"><thead><tr><th>Metric</th><th>Value</th></tr></thead><tbody></tbody></table>').find('tbody')
    for row, i in data.chart_data
      if row.length == 3 && data.id
        value = "<a href='#{@value_with_where_link(container, data, i)}'>#{row[1]}</a>"
      else
        value = row[1]
      metric = $('<tr>').html("<th>#{row[0]}</th><td>#{value}</td>")
      tbody.append(metric)

  value_with_where_link: (wrapper, data, index) ->
    link = wrapper.parents(".widget").find("h4 a").attr('href')
    sep = if (link.indexOf("?") isnt -1) then '&' else '?'
    if data.chart_type == 'TimeChart'
      value = "#{data.chart_data[index][2]}&grouping=#{data.grouping}"
    else
      value = data.chart_data[index][2]
    link += "#{sep}where[#{data.column}]=#{value}"
  
  graphData: (data, container) =>
    return @dataBeforeGoogleChartsLoad.push [data, container] unless @googleChartsLoaded
    container ||= '#chart_div'
    data ||= window.data_for_graph
    if data.chart_data is null
      $(container).text "No data to chart for this grouping value."
      return
    
    if data.chart_type is 'StatChart'
      @statChart(data, container)
      return
    
    dataTable = new google.visualization.DataTable()
    
    dataTable.addColumn 'string', column_type
    dataTable.addColumn 'number', 'Count'
    if data.chart_type is 'TimeChart'
      column_type = 'none'
      legend = 'none'
      colors = ['#7d72bd']
    else
      column_type = 'Column'
      legend = {position: 'right'}
      colors = (row[3] for row in data.chart_data)
    
    rows = ([String(row[0]), row[1]] for row in data.chart_data)
    dataTable.addRows rows
    wrapper = $(container)
    width = wrapper.parent().css('width')
    if width is '0px'
      setTimeout =>
        @graphData(data, container)
      , 125
    options = {width: width, height:300, colors: colors, legend: legend, chartArea:{top:15, left: '5%', height: '75%', width:'90%'}}
    if data.chart_type is 'TimeChart'
      chart = new google.visualization.ColumnChart(wrapper.get(0))
    else
      chart = new google.visualization.PieChart(wrapper.get(0))
    chart.draw(dataTable, options)
    google.visualization.events.addListener chart, 'select', =>
      index = chart.getSelection()[0].row
      link = wrapper.parents(".widget").find("h4 a").attr('href') || location.href
      sep = if (link.indexOf('?') isnt -1) then '&' else '?'
      if data.chart_type is 'PieChart'
        value = data.chart_data[index][2]
      else
        value = "#{data.chart_data[index][2]}&grouping=#{data.grouping}"
      link += "#{sep}where[#{data.column}]=#{value}"
      location.href = link
    $('#time-chart i[rel=tooltip]').tooltip()

$ ->
  window.time_charts = new TimeCharts()


window.remoteModal = (selector, params, callback) ->
  $(selector).html($('.loading_modal').html()).modal('show')
  path = $(selector).data('remote-path')
  for key, value of params
    path = path.replace(encodeURIComponent("{#{key}}"), value)
  $.get path, (data) =>
    $(selector).html(data)
    callback() if callback
