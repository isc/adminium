class Navigation

  constructor: ->
    @itemList()
    @tableSelection()
    @searchBar()

  tableSelection: ->
    @selector = '#search-table .search-query'
    $(document).on 'change', @selector, ->
      if $(this).data('source').indexOf(this.value) isnt -1
        this.form.action = this.form.action + this.value
        $(this).tooltip('show')
        this.form.submit()

    $("#search-table").on 'submit', ->
      this.action = this.action + $(this).find('input').val()
      $(this).tooltip('show')

    $(document).keypress (e) =>
      return if $(event.target).is(':input')
      if e.which is 115 # 's' key
        $(@selector).focus().focus() # Double focus call needed because of the typeahead plugin applied to this field
        e.preventDefault()
      if e.which is 99 # 'c' for create
        location.href = $('a.btn.create')[0].href if $('a.btn.create').length

  searchBar: ->
    $(document).keypress (e) =>
      return if $(event.target).is(':input')
      if e.which is 47
        $('form.subnav-search input[type=text]').focus()
        e.preventDefault()

  itemList: ->
    $(document).keydown (e) =>
      return if $(event.target).is(':input') or $('.items-list').length is 0
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
        location.href = row.find('td:first-child a:first-child').attr('href')
      else if e.which is 88 # x
        checkBox = row.find('td:eq(1) input[type=checkbox]').get(0).click()
      else if e.which is 84 # t
        row.find('td:first-child a:last-child').trigger('click')
      else if e.which is 69 # e
        location.href = row.find('td:first-child a:eq(1)').attr('href')
      else
        return
      e.preventDefault()

$ -> new Navigation()
