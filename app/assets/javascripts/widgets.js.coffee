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
    $('#widget_table').change ->
      $.getJSON "/searches/#{this.value}", (data) ->
        return unless data.length
        for search in data
          $('<option>').text(search).val(search).appendTo('#widget_advanced_search')
        $('#widget_advanced_search').closest('.control-group').parent().show()

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
        widget.find('.content tr td').click (evt) ->
          link = $(evt.currentTarget).find('a')
          if link.length
            link.replaceWith $("#facebookG").clone()
            window.location.href = link.attr('href')
        widget.find('h4 small').show().find('span').text(data.total_count)
      else
        time_charts.graphData data.graph_data, widget.find('.content')

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
