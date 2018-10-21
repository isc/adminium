class TimeCharts

  constructor: ->
    @setupTimeChartsCreation()
    @setupGroupingChange()

  setupTimeChartsCreation: ->
    $('th i.time-chart').click (e) =>
      remoteModal '#time-chart', $(e.currentTarget).data('path'), @graphData
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
    value = data.chart_data.keys[index]
    value = "#{value}&grouping=#{data.grouping}" if data.chart_type is 'TimeChart'
    link = $(wrapper).parents('.widget').find('h4 a').attr('href') || location.href
    sep = if (link.indexOf('?') isnt -1) then '&' else '?'
    "#{link}#{sep}where[#{data.column}]=#{value}"

  graphData: (data, container) =>
    container ||= '#chart_div'
    wrapper = $(container)
    data ||= window.data_for_graph
    return setTimeout (=> @graphData(data, container)), 125 if wrapper.parent().css('width') is '0px'
    return wrapper.text data.error if data.error
    return wrapper.text 'No data to chart for this grouping value.' if data.chart_data is null
    return @statChart(data, container) if data.chart_type is 'StatChart'
    type = if data.chart_type is 'TimeChart' then 'bar' else 'percentage'
    height = if data.chart_type is 'TimeChart' then 300 else 200
    chart = new frappe.Chart container, {
      data: data.chart_data, type: type, height: height, colors: data.chart_data.colors,
      axisOptions: { xIsSeries: 1, xAxisMode: 'tick' }, isNavigable: true }
    chart.parent.addEventListener 'data-select', (e) => location.href = @valueWithWhereLink(wrapper, data, e.index)
    $('#time-chart i[rel=tooltip]').tooltip()

$ -> window.time_charts = new TimeCharts()

window.remoteModal = (selector, path, callback) ->
  $(selector).html($('.loading_modal').html()).modal('show')
  $.get path, (data) =>
    $(selector).html(data)
    callback() if callback
