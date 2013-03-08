class Charts
  
  constructor: ->
    @setupTimeChartsCreation()
    @setupGroupingChange()
  
  setupTimeChartsCreation: ->
    $('th i.time-chart').click (e) =>
      @column_name = $(e.currentTarget).closest('.column_header').data('column-name')
      remoteModal '#time-chart', {column: @column_name}, @graphData
  
  setupGroupingChange: ->
    $(document).on 'change', '#time-chart.modal #grouping', (e) =>
      remoteModal '#time-chart', {column: "#{@column_name}&grouping=#{e.currentTarget.value}"}, @graphData
  
  graphData: =>
    data = new google.visualization.DataTable()
    data.addColumn('string', 'Date')
    data.addColumn('number', 'Count')
    chart_data.shift()
    data.addRows chart_data
    wrapper = $('#chart_div')
    options = {width: wrapper.parent().css('width'), height:300, colors: ['#7d72bd']}
    chart = new google.visualization.ColumnChart(wrapper.get(0))
    chart.draw(data, options)
  
$ ->
  new Charts()


window.remoteModal = (selector, params, callback) ->
  $(selector).html($(".loading_modal").html()).modal('show')
  path = $(selector).data('remote-path')
  for key, value of params
    path = path.replace(encodeURIComponent("{#{key}}"), value)
  $.get path, (data) =>
    $(selector).html(data)
    callback() if callback
