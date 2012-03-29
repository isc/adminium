class TableNavigation

  constructor: ->
    @input = $('#search-table .search-query')
    $("#search-table").submit (e) =>
      window.location.href = "/resources/#{@input.val()}"
      e.preventDefault()
    @focusKey()

  focusKey: ->
    $(document).keypress (e) =>
      return if $(event.target).is(':input')
      if e.which is 115 # 's' key
        @input.focus()
        @input.focus()
        e.preventDefault()

$ -> new TableNavigation()
