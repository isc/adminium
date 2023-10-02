class Widget

  constructor: ->
    @setupSorting()
    @fetchContent widget for widget in $('.widget')
    @setupCreationFromDashboard()
    @setupCreationFromListing()
    @setupDeletion()

  setupCreationFromDashboard: ->
    $('#widget_table').change (e) =>
      @fillColumnsSelection e.target.value
    $('input[name="widget[type]"]').click (e) =>
      $('#widget_columns').closest('.form-group').parent().toggleClass('hidden', e.target.value is 'TableWidget')
      $('#widget_grouping').closest('.form-group').parent().toggleClass('hidden', e.target.value isnt 'TimeChartWidget')
      return unless table = $('#widget_table').val()
      @fillColumnsSelection table

  fetchAdvancedSearches: (table) ->
    return unless table
    $.getJSON "/searches/#{table}", (data) ->
      if data.length
        $('#widget_advanced_search').empty().append($('<option>'))
        $('<option>').text(search).val(search).appendTo('#widget_advanced_search') for search in data
      $('#widget_advanced_search').closest('.form-group').parent().toggleClass('hidden', data.length is 0)

  fillColumnsSelection: (table) ->
    @fetchAdvancedSearches table
    widgetType = $('input[name="widget[type]"]:checked').val()
    $('#widget_columns').empty().prop('required', widgetType isnt 'TableWidget')
    return if widgetType is 'TableWidget'
    $.getJSON "/settings/columns?table=#{table}&chart_type=#{widgetType}", (data) ->
      $('<option>').text(column).val(column).appendTo('#widget_columns') for column in data

  setupCreationFromListing: ->
    $('#time-chart').on 'click', '.add_widget', (evt) ->
      target = $(evt.currentTarget)
      target.removeClass('subtle add_widget')
      $(target.data('form')).submit()

  fetchContent: (widget) ->
    $.getJSON $(widget).data('query-url'), (data) =>
      widget = $(".widget[data-widget-id=#{data.id}]")
      if data.widget
        widget.find('.content').html(data.widget)
        widget.find('.content a[rel*=tooltip]').tooltip(container: 'body')
        widget.find('.content tr td').click (evt) ->
          link = $(evt.currentTarget).find('a')
          window.location.href = link.attr('href') if link.length
        widget.find('h4 small').removeClass('hidden').find('span').text(data.total_count) if data.total_count
      else
        time_charts.graphData data, widget.find('.content')

  setupDeletion: ->
    $('.widget .btn-mini').on 'ajax:success', -> $(this).closest('.widget').remove()

  updateWidgetSorting: (id, data) ->
    $.ajax "/widgets/#{id}", type: 'PUT', data: { widget: data }

  setupSorting: ->
    $('.widget .content').on 'click', 'th.column_header a', (ev) =>
      href = $(ev.currentTarget).attr('href')
      widget = $(ev.currentTarget).parents('.widget')
      regexp = new RegExp("order=(.*)&")
      result = href.match(regexp)
      query_url = widget.data("query-url")
      if query_url.match(regexp)
        query_url = query_url.replace(regexp, result[0])
      else
        query_url = query_url.replace("?", "?#{result[0]}")
      widget.data("query-url", query_url)
      @fetchContent widget
      @updateWidgetSorting(widget.data('widget-id'), {order:decodeURIComponent(result[1]).replace("+", " ")})
      ev.preventDefault()

$ -> new Widget()
