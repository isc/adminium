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
    $('th i.time-chart').click (e) => remoteModal '#time-chart', $(e.currentTarget).data('path'), @graphData
    $(document).on 'click', '#time-chart.modal a.evolution-chart', (e) =>
      href = $(e.currentTarget).attr('href')
      remoteModal '#time-chart', href, @evolutionChart(href)
      false

  setupGroupingChange: ->
    $(document).on 'change', '#time-chart.modal #grouping', (e) =>
      remoteModal '#time-chart', "#{$(e.currentTarget).data('path')}&grouping=#{e.currentTarget.value}", @graphData

  statChart: (data, container) =>
    tbody = $(container).html('<table class="table table-condensed"><thead><tr><th>Metric</th><th>Value</th></tr></thead><tbody></tbody></table>').find('tbody')
    for row, i in data.chart_data
      value = if row.length is 3 then "<a href='#{@valueWithWhereLink(container, data, i)}'>#{row[1]}</a>" else row[1]
      metric = $('<tr>').html("<th>#{row[0]}</th><td>#{value}</td>")
      tbody.append(metric)

  evolutionChart: (path) => =>
    dataTable = new google.visualization.DataTable()
    dataTable.addColumn 'datetime'
    dataTable.addColumn 'number', name for name, _ of window.data_for_graph.chart_data
    wrapper = $('#chart_div')
    width = wrapper.parent().css('width')
    options = { width: width, height: 300, chartArea: { top: 15, left: '5%', height: '75%', width: '50%' } }
    chart = new google.visualization.LineChart(wrapper.get(0))
    chart.draw(dataTable, options)
    previousDataset = window.data_for_graph.chart_data
    @evolutionChartInterval = setInterval =>
      $.getJSON path, (data) =>
        newRow = [new Date()]
        newRow.push(data[name] - previousDataset[name]) for name, _ of window.data_for_graph.chart_data
        dataTable.addRows([newRow])
        chart.draw(dataTable, options)
        previousDataset = data
        clearInterval @evolutionChartInterval unless $('#chart_div:visible').length
    , 5000

  valueWithWhereLink: (wrapper, data, index) ->
    value = data.chart_data[index][2]
    value += "&grouping=#{data.grouping}" if data.chart_type is 'TimeChart'
    link = $(wrapper).parents('.widget').find('h4 a').attr('href') || location.href
    sep = if (link.indexOf('?') isnt -1) then '&' else '?'
    "#{link}#{sep}where[#{data.column}]=#{value}"

  graphData: (data, container) =>
    return @dataBeforeGoogleChartsLoad.push [data, container] unless @googleChartsLoaded
    container ||= '#chart_div'
    data ||= window.data_for_graph
    wrapper = $(container)
    return @alertDiv(wrapper, data.error, 'danger') if data.error
    return @alertDiv(wrapper, 'No data to chart for this grouping value.', 'info') unless data.chart_data.length
    return @statChart(data, container) if data.chart_type is 'StatChart'
    width = wrapper.parent().css('width')
    return setTimeout (=> @graphData(data, container)), 125 if width is '0px'

    dataTable = new google.visualization.DataTable()
    dataTable.addColumn 'string'
    dataTable.addColumn 'number', 'Count'
    dataTable.addRows ([String(row[0]), row[1]] for row in data.chart_data)
    if data.chart_type is 'TimeChart'
      legend = 'none'
      colors = ['#7d72bd']
    else
      legend = { position: 'right' }
      colors = (row[3] for row in data.chart_data)
    options = {
      width: width, height:300, colors: colors, legend: legend,
      chartArea: {top:15, left: '5%', height: '75%', width:'90%'}
    }
    chart = if data.chart_type is 'TimeChart'
      new google.visualization.ColumnChart(wrapper.get(0))
    else
      new google.visualization.PieChart(wrapper.get(0))
    chart.draw(dataTable, options)
    google.visualization.events.addListener chart, 'select', =>
      location.href = @valueWithWhereLink wrapper, data, chart.getSelection()[0].row
    $('#time-chart i[rel=tooltip]').tooltip()

  alertDiv: (container, message, level) => container.html("<div class='alert alert-#{level}'>#{message}</div>")

$ -> window.time_charts = new TimeCharts()

window.remoteModal = (selector, path, callback) ->
  $(selector).html($('.loading_modal').html()).modal('show')
  $.get path, (data) =>
    $(selector).html(data)
    callback() if callback
