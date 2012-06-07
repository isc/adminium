class Widget
  
  constructor: ->
    @fetchContent()
    @setupCreation()
    @setupDeletion()
    
  setupCreation: ->
    $('#widget_table').change ->
      $.getJSON "/searches/#{this.value}", (data) ->
        return unless data.length
        for search in data
          $('<option>').text(search).val(search).appendTo('#widget_advanced_search')
        $('#widget_advanced_search').closest('.control-group').parent().show()
  
  fetchContent: ->
    for widget in $('.widget')
      $.get $(widget).data('query-url'), (data) =>
        widget = $(".widget[data-widget-id=#{data.id}]")
        widget.find('.content').html(data.widget)
        widget.find('h4 small').show().find('span').text(data.total_count)
  
  setupDeletion: ->
    $('.widget .btn-mini').bind 'ajax:success', ->
      $(this).closest('.widget').remove()
  
$ -> new Widget()
