class Widget

  constructor: ->
    @setupSorting()
    @fetchAllContent()
    @setupCreation()
    @setupDeletion()

  setupCreation: ->
    $('#widget_table').change ->
      $.getJSON "/searches/#{this.value}", (data) ->
        return unless data.length
        for search in data
          $('<option>').text(search).val(search).appendTo('#widget_advanced_search')
        $('#widget_advanced_search').closest('.control-group').parent().show()

  fetchAllContent: ->
    @fetchContent widget for widget in $('.widget')

  fetchContent: (widget) ->
    $.get $(widget).data('query-url'), (data) =>
      widget = $(".widget[data-widget-id=#{data.id}]")
      widget.find('.content').html(data.widget)
      widget.find('h4 small').show().find('span').text(data.total_count)

  setupDeletion: ->
    $('.widget .btn-mini').bind 'ajax:success', ->
      $(this).closest('.widget').remove()

  updateWidgetSorting: (id, data) ->
    d = {type:"PUT", data:{widget:data}}
    $.ajax("/widgets/#{id}", d)

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
      @updateWidgetSorting(widget.data('widget-id'), {order:result[1].replace("+", " ")})
      ev.preventDefault()

$ -> new Widget()
