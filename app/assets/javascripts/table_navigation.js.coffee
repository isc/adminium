class TableNavigation

  constructor: ->
    @input = $('#search-table .search-query')
    @input.change ->
      this.form.action = this.form.action + this.value
      this.form.submit()
    @focusKey()

  focusKey: ->
    $(document).keypress (e) =>
      return if $(event.target).is(':input')
      if e.which is 115 # 's' key
        @input.focus()
        e.preventDefault()

$ -> new TableNavigation()
