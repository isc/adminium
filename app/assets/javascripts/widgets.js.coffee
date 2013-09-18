class Widget

  constructor: ->
    @setupSorting()
    @fetchAllContent()
    @setupCreationFromDashboard()
    @setupCreationFromListing()
    @setupDeletion()

  setupCreationFromDashboard: ->
    if $('#plan').text() is 'petproject'
      for option, i in $('#widget_table').find('option') when i > 5
        $(option).attr('disabled', 'disabled')
    $('#widget_table').change (e) =>
      if $('input[name="widget[type]"]:checked').val() is 'TableWidget'
        @fetchAdvancedSearches e.target.value
      else
        @fetchDateColumns e.target.value
    $('input[name="widget[type]"]').click (e) =>
      $('div[data-widget-type="TableWidget"]').toggle(e.target.value is 'TableWidget')
      $('div[data-widget-type="TimeChartWidget"]').toggle(e.target.value is 'TimeChartWidget')
      $('#widget_columns').attr('required', e.target.value is 'TimeChartWidget')
      return unless table = $('#widget_table').val()
      if e.target.value is 'TimeChartWidget' then @fetchDateColumns table else @fetchAdvancedSearches table

  fetchAdvancedSearches: (table) ->
    $.getJSON "/searches/#{table}", (data) ->
      if data.length
        $('#widget_advanced_search').empty().append($('<option>'))
        $('<option>').text(search).val(search).appendTo('#widget_advanced_search') for search in data
      $('#widget_advanced_search').closest('.control-group').parent().toggle(data.length isnt 0)

  fetchDateColumns: (table) ->
    $.getJSON "/settings/columns?table=#{table}&time_chart=true", (data) ->
      $('#widget_columns').empty()
      $('<option>').text(column).val(column).appendTo('#widget_columns') for column in data

  setupCreationFromListing: ->
    $('#nav_searches, #time-chart').on 'click', 'i.add_widget', (evt) ->
      $(evt.currentTarget).addClass('active').removeClass('add_widget')
      $($(evt.currentTarget).data('form')).submit()

  fetchAllContent: ->
    @fetchContent widget for widget in $('.widget')

  fetchContent: (widget) ->
    $.getJSON $(widget).data('query-url'), (data) =>
      widget = $(".widget[data-widget-id=#{data.id}]")
      if data.widget
        widget.find('.content').html(data.widget)
        widget.find('.content a[rel*=tooltip]').tooltip()
        widget.find('.content tr td').click (evt) ->
          link = $(evt.currentTarget).find('a')
          if link.length
            link.replaceWith $("#facebookG").clone()
            window.location.href = link.attr('href')
        widget.find('h4 small').show().find('span').text(data.total_count)
      else
        time_charts.graphData data, widget.find('.content')

  setupDeletion: ->
    $('.widget .btn-mini').bind 'ajax:success', ->
      $(this).closest('.widget').remove()

  updateWidgetSorting: (id, data) ->
    $.ajax "/widgets/#{id}", type: "PUT", data: {widget: data}

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
