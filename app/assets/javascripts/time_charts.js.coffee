class TimeCharts
  
  constructor: ->
    @datas = {}
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
      remoteModal '#time-chart', {column: @column_name}, @graphData
      _gaq.push ['_trackPageview', '/time_chart'] if window['_gaq']

  setupGroupingChange: ->
    $(document).on 'change', '#time-chart.modal #grouping', (e) =>
      remoteModal '#time-chart', {column: "#{@column_name}&grouping=#{e.currentTarget.value}"}, @graphData
  
  graphData: (data, container, d) =>
    return @dataBeforeGoogleChartsLoad.push [data, container, d] unless @googleChartsLoaded
    data ||= chart_data
    container ||= '#chart_div'
    if data is null
      $(container).text "No data to chart for this grouping value."
      return
    dataTable = new google.visualization.DataTable()
    dataTable.addColumn 'string', 'Date'
    dataTable.addColumn 'number', 'Count'
    
    rows = ([String(row[0]), row[1]] for row in data)
    dataTable.addRows rows
    wrapper = $(container)
    if d
      @datas[d.id] = {data: (row[2] for row in data)}
    width  = wrapper.parent().css('width')
    if width == '0px'
      setTimeout () =>
        @graphData(data, container, d)
      , 125
    options = {width: width, height:300, colors: ['#7d72bd'], legend: 'none', chartArea:{top:15, left: '5%', height: '75%', width:'90%'}}
    chart = new google.visualization.ColumnChart(wrapper.get(0))
    chart.draw(dataTable, options)
    if d
      google.visualization.events.addListener chart, 'select', () =>
        value = @datas[d.id].data[chart.getSelection()[0].row]
        link = wrapper.parents(".widget").find("h4 a").attr('href')
        sep = if (link.indexOf("?") isnt -1) then '&' else '?'
        link += "#{sep}where[#{d.column}]=#{value}&grouping=#{d.grouping}"
        window.location.href = link
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
