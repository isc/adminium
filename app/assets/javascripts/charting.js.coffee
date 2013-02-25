class Charting

  constructor: ->
    newScript = document.createElement('script');
    newScript.type = 'text/javascript';
    newScript.src = 'https://www.google.com/jsapi';
    document.getElementsByTagName("head")[0].appendChild(newScript);
    setTimeout @load, 100

  load: =>
    if window.hasOwnProperty 'google'
      google.load 'visualization', '1', {'callback':@drawCharts, 'packages':['corechart']}
    else
      setTimeout @load, 100

  drawCharts: =>
    for pie in $(".sparkline-pie")
      table
      table = $(pie).data('table')
      colors = $(pie).data('colors')

      data = google.visualization.arrayToDataTable([['label', 'value']].concat(table))
      options =
        legend: 'none'
        'backgroundColor': '#6d61b4'
        pieSliceBorderColor: '#6d61b4'
        colors: colors
        height: 75
        width: 75
        pieSliceText: 'none'
        tooltip: {textStyle:{fontSize: 10}}

      chart = new google.visualization.PieChart(pie)
      chart.draw data, options

$ ->
  new Charting()