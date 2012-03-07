class TableNavigation
  
  constructor: ->
    @input = $('.sidebar-nav .search-query')
    @focusKey()
    @input.keyup (e) =>
      return if @gotoTable(e)
      return if @arrowNavigation(e)
      @filtering()
    
  filtering: ->
    value = @input.val().toLowerCase()
    # return unless value.length
    $('.sidebar-nav li:not(.nav-header)').each ->
      table = $(this).text().toLowerCase()
      $(this).toggle(!!table.match(value))
    $('.sidebar-nav li:not(.nav-header)').removeClass('active')
      .filter(':visible:first').addClass('active')

  focusKey: ->
    $(document).keypress (e) =>
      return if $(event.target).is(':input')
      if e.which is 115 # 's' key
        @input.focus()
        e.preventDefault()
  
  gotoTable: (e) ->
    if e.which is 13 # enter key
      window.location.href = $('.sidebar-nav li.active a').attr('href')

  arrowNavigation: (e) ->
    return if [38, 40].indexOf(e.which) is -1
    current = $('.sidebar-nav li.active')
    if e.which is 38 # up arrow
      if current.prev(':visible').length and not current.prev(':visible').hasClass('nav-header')
        current.removeClass('active').prev(':visible').addClass('active')
    if e.which is 40 # down arrow
      if current.next(':visible').length
        current.removeClass('active').next(':visible').addClass('active')
    true

$ -> new TableNavigation()
