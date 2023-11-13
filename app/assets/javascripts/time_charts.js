class TimeCharts {
  constructor() {
    const newScript = document.createElement('script')
    newScript.type = 'text/javascript'
    newScript.src = 'https://www.google.com/jsapi'
    document.getElementsByTagName('head')[0].appendChild(newScript)
    this.setupTimeChartsCreation()
    this.setupGroupingChange()
    this.dataBeforeGoogleChartsLoad = []
    this.loadGoogleCharts()
  }

  loadGoogleCharts() {
    if (window.hasOwnProperty('google'))
      google.load('visualization', '1', {
        callback: () => this.googleChartsLoadCallback(),
        packages: ['corechart']
      })
    else setTimeout(() => this.loadGoogleCharts(), 100)
  }

  googleChartsLoadCallback() {
    this.googleChartsLoaded = true
    this.dataBeforeGoogleChartsLoad.forEach(args => this.graphData(...args))
  }

  setupTimeChartsCreation() {
    $('th i.time-chart').click(e =>
      remoteModal('#time-chart', $(e.currentTarget).data('path'), () =>
        this.graphData()
      )
    )
    $(document).on('click', '#time-chart.modal a.evolution-chart', e => {
      const href = $(e.currentTarget).attr('href')
      remoteModal('#time-chart', href, () => this.evolutionChart(href))
      return false
    })
  }

  setupGroupingChange() {
    $(document).on('change', '#time-chart.modal #grouping', e =>
      remoteModal(
        '#time-chart',
        `${$(e.currentTarget).data('path')}&grouping=${e.currentTarget.value}`,
        () => this.graphData()
      )
    )
  }

  statChart(data, container) {
    const tbody = $(container)
      .html(
        '<table class="table table-condensed"><thead><tr><th>Metric</th><th>Value</th></tr></thead><tbody></tbody></table>'
      )
      .find('tbody')
    data.chart_data.forEach((row, i) => {
      const value =
        row.length == 3
          ? `<a href='${this.valueWithWhereLink(container, data, i)}'>${
              row[1]
            }</a>`
          : row[1]
      const metric = $('<tr>').html(`<th>${row[0]}</th><td>${value}</td>`)
      tbody.append(metric)
    })
  }

  evolutionChart(path) {
    const dataTable = new google.visualization.DataTable()
    dataTable.addColumn('datetime')
    Object.keys(window.data_for_graph.chart_data).forEach(name =>
      dataTable.addColumn('number', name)
    )
    const wrapper = $('#chart_div')
    const width = wrapper.parent().css('width')
    const options = {
      width: width,
      height: 300,
      chartArea: { top: 15, left: '5%', height: '75%', width: '50%' }
    }
    const chart = new google.visualization.LineChart(wrapper.get(0))
    chart.draw(dataTable, options)
    var previousDataset = window.data_for_graph.chart_data
    this.evolutionChartInterval = setInterval(() => {
      $.getJSON(path, data => {
        const newRow = [new Date()]
        Object.keys(window.data_for_graph.chart_data).forEach(name =>
          newRow.push(data[name] - previousDataset[name])
        )
        dataTable.addRows([newRow])
        chart.draw(dataTable, options)
        previousDataset = data
        if (!$('#chart_div:visible').length)
          clearInterval(this.evolutionChartInterval)
      })
    }, 5000)
  }

  valueWithWhereLink(wrapper, data, index) {
    var value = data.chart_data[index][2]
    if (data.chart_type == 'TimeChart') value += `&grouping=${data.grouping}`
    const link =
      $(wrapper).parents('.widget').find('h4 a').attr('href') || location.href
    const sep = link.indexOf('?') !== -1 ? '&' : '?'
    return `${link}${sep}where[${data.column}]=${value}`
  }

  graphData(data, container) {
    if (!this.googleChartsLoaded)
      return this.dataBeforeGoogleChartsLoad.push([data, container])
    container ||= '#chart_div'
    data ||= window.data_for_graph
    const wrapper = $(container)
    if (data.error) return this.alertDiv(wrapper, data.error, 'danger')
    if (!data.chart_data.length)
      return this.alertDiv(
        wrapper,
        'No data to chart for this grouping value.',
        'info'
      )
    if (data.chart_type == 'StatChart') return this.statChart(data, container)
    const width = wrapper.parent().css('width')
    if (width == '0px')
      return setTimeout(() => this.graphData(data, container), 125)
    const dataTable = new google.visualization.DataTable()
    dataTable.addColumn('string')
    dataTable.addColumn('number', 'Count')
    dataTable.addRows(data.chart_data.map(row => [String(row[0]), row[1]]))
    var legend, colors
    if (data.chart_type == 'TimeChart') {
      legend = 'none'
      colors = ['#7d72bd']
    } else {
      legend = { position: 'right' }
      colors = data.chart_data.map(row => row[3])
    }
    const options = {
      width: width,
      height: 300,
      colors: colors,
      legend: legend,
      chartArea: { top: 15, left: '5%', height: '75%', width: '90%' }
    }
    const chart =
      data.chart_type == 'TimeChart'
        ? new google.visualization.ColumnChart(wrapper.get(0))
        : new google.visualization.PieChart(wrapper.get(0))
    chart.draw(dataTable, options)
    google.visualization.events.addListener(
      chart,
      'select',
      () =>
        (location.href = this.valueWithWhereLink(
          wrapper,
          data,
          chart.getSelection()[0].row
        ))
    )
    $('#time-chart i[rel=tooltip]').tooltip()
  }

  alertDiv(container, message, level) {
    container.html(`<div class='alert alert-${level}'>${message}</div>`)
  }
}

$(() => (window.time_charts = new TimeCharts()))

window.remoteModal = (selector, path, callback) => {
  $(selector).html($('.loading_modal').html()).modal('show')
  $.get(path, data => {
    $(selector).html(data)
    if (callback) callback()
  })
}
