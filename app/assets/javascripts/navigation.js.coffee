class Navigation

  constructor: ->
    @itemList()
    @tableSelection()
    @searchBar()

  tableSelection: ->
    @input = $('#search-table .search-query')
    @input.change ->
      this.form.action = this.form.action + this.value
      this.form.submit()
    $(document).keypress (e) =>
      return if $(event.target).is(':input')
      if e.which is 115 # 's' key
        @input.focus().focus() # Double focus call needed because of the typeahead plugin applied to this field
        e.preventDefault()

  searchBar: ->
    $(document).keypress (e) =>
      return if $(event.target).is(':input')
      if e.which is 47
        $('form.subnav-search input[type=text]').focus()
        e.preventDefault()

  itemList: ->
    return unless $('.items-list').length
    $('.items-list tbody tr').click ->
      window.location.href = $(this).find('td:first-child a:first-child').attr('href')
    $(document).keydown (e) =>
      return if $(event.target).is(':input')
      row = $('.items-list tr.selected')
      if row.length is 0
        if [74, 40].indexOf(e.which) isnt -1
          $('.items-list tbody tr').first().addClass('selected')
          e.preventDefault()
        return
      if [74, 40].indexOf(e.which) isnt -1 # j or down arrow
        row.removeClass('selected').next().addClass('selected') if row.next().length
      else if [75, 38].indexOf(e.which) isnt -1 # k or up arrow
        row.removeClass('selected').prev().addClass('selected') if row.prev().length
      else if [13, 39, 79].indexOf(e.which) isnt -1 # return or right arrow or o
        window.location.href = row.find('td:first-child a:first-child').attr('href')
      else if e.which is 88 # x
        checkBox = row.find('td:eq(1) input[type=checkbox]')
        checkBox.attr('checked', !checkBox.attr('checked'))
      else if e.which is 84 # t
        row.find('td:first-child a:last-child').trigger('click')
      else if e.which is 69 # e
        window.location.href = row.find('td:first-child a:eq(1)').attr('href')
      else
        return
      e.preventDefault()

$ -> new Navigation()
