class Widget {
  constructor() {
    this.setupSorting()
    $('.widget').each((_, widget) => this.fetchContent(widget))
    this.setupCreationFromDashboard()
    this.setupCreationFromListing()
    this.setupDeletion()
  }

  setupSorting() {
    $('.widget .content').on('click', 'th.column_header a', ev => {
      const href = $(ev.currentTarget).attr('href')
      const widget = $(ev.currentTarget).parents('.widget')
      const regexp = new RegExp('order=(.*)&')
      const result = href.match(regexp)
      var query_url = widget.data('query-url')
      query_url = query_url.match(regexp)
        ? query_url.replace(regexp, result[0])
        : query_url.replace('?', `?${result[0]}`)
      widget.data('query-url', query_url)
      this.fetchContent(widget)
      $.ajax(`/widgets/${widget.data('widget-id')}`, {
        type: 'PUT',
        data: {
          widget: {
            order: decodeURIComponent(result[1]).replace('+', ' ')
          }
        }
      })
      ev.preventDefault()
    })
  }

  fetchContent(widget) {
    $.getJSON($(widget).data('query-url'), data => {
      const widget = $(`.widget[data-widget-id=${data.id}]`)
      if (data.widget) {
        widget.find('.content').html(data.widget)
        widget.find('.content a[rel*=tooltip]').tooltip({ container: 'body' })
        widget.find('.content tr td').click(evt => {
          link = $(evt.currentTarget).find('a')
          if (link.length) window.location.href = link.attr('href')
        })
        if (data.total_count)
          widget
            .find('h4 small')
            .removeClass('hidden')
            .find('span')
            .text(data.total_count)
      } else time_charts.graphData(data, widget.find('.content'))
    })
  }

  setupCreationFromDashboard() {
    $('#widget_table').change(e => this.fillColumnsSelection(e.target.value))
    $('input[name="widget[type]"]').click(e => {
      $('#widget_columns')
        .closest('.form-group')
        .parent()
        .toggleClass('hidden', e.target.value == 'TableWidget')
      $('#widget_grouping')
        .closest('.form-group')
        .parent()
        .toggleClass('hidden', e.target.value != 'TimeChartWidget')
      const table = $('#widget_table').val()
      if (table) this.fillColumnsSelection(table)
    })
  }

  setupCreationFromListing() {
    $('#time-chart').on('click', '.add_widget', evt => {
      target = $(evt.currentTarget)
      target.removeClass('subtle add_widget')
      $(target.data('form')).submit()
    })
  }

  setupDeletion() {
    $('.widget .btn-mini').on('ajax:success', function () {
      $(this).closest('.widget').remove()
    })
  }

  fetchAdvancedSearches(table) {
    if (!table) return
    $.getJSON(`/searches/${table}`, data => {
      if (data.length) {
        $('#widget_advanced_search').empty().append($('<option>'))
        data.forEach(search =>
          $('<option>')
            .text(search)
            .val(search)
            .appendTo('#widget_advanced_search')
        )
      }
      $('#widget_advanced_search')
        .closest('.form-group')
        .parent()
        .toggleClass('hidden', data.length == 0)
    })
  }

  fillColumnsSelection(table) {
    this.fetchAdvancedSearches(table)
    const widgetType = $('input[name="widget[type]"]:checked').val()
    $('#widget_columns')
      .empty()
      .prop('required', widgetType != 'TableWidget')
    if (widgetType == 'TableWidget') return
    $.getJSON(
      `/settings/columns?table=${table}&chart_type=${widgetType}`,
      data =>
        data.forEach(column =>
          $('<option>').text(column).val(column).appendTo('#widget_columns')
        )
    )
  }
}

$(() => new Widget())
