class Navigation

  constructor: ->
    @helpShown = false
    @itemList()
    @tableSelection()
    @searchBar()
    @applist()

  applist: ->
    $(".apps-list").hover @fetchAppList
    $(".apps-list").click @fetchAppList
      
  
  fetchAppList: ->
    return if $(".apps-list").data('fetched')
    $(".apps-list").data('fetched', true)
    $.get "/user/apps", (data) ->
      $("ul.accounts-menu").html(data)
    
  tableSelection: ->
    options = {placeholder: "Jump to table (s to focus)", allowClear: true}
    options.matcher = adminiumSelect2Matcher
    @selector = '#table_select'
    $(@selector).select2(options).removeClass('hidden').on 'change', (object) =>
      $(@selector).select2('destroy').closest('form').replaceWith('<div class="navbar-text">Loading...</div>')
      window.location.href = "/resources/#{object.val}"
    $('.modal').on 'hide', ->
      $(this).find('input:focus').blur()

    $(document).keypress (e) =>
      return if $(e.target).is(':input')
      if e.which is 115 # 's' key
        $(@selector).select2('open')
        e.preventDefault()
      for action, key of {create: 99, destroy: 116, edit: 101}
        if e.which is key and $("a.btn.#{action}-action").length
          $("a.btn.#{action}-action").get(0).click()
      if e.which is 63 # '?' for help
        @toggleKeyboardShortcutsHelp()

  toggleKeyboardShortcutsHelp: ->
    selector = '#keyboard-shortcuts-help'
    if @helpShown
      $(selector).modal('hide')
      @helpShown = false
    else
      if $(selector).length
        $(selector).modal('show')
      else
        docs_url = '/docs/keyboard_shortcuts?no_layout=true'
        $('<div>').attr('id', selector.replace('#', '')).addClass('modal fade')
          .appendTo('body').html($(".loading_modal").html()).modal('show')
        $.get docs_url, (data) => $(selector).html(data)
        $(selector).on 'hidden', => @helpShown = false
        _gaq.push ['_trackPageview', docs_url] if window['_gaq']
      @helpShown = true
  
  searchBar: ->
    $(document).keypress (e) =>
      return if $(e.target).is(':input')
      if e.which is 47
        $('form.navbar-form input[type=text]').focus()
        e.preventDefault()

  itemList: ->
    $(document).keydown (e) =>
      return if $(e.target).is(':input') or $('.items-list').length is 0
      row = $('.items-list tr.success')
      if row.length is 0
        if [74, 40].indexOf(e.which) isnt -1
          $('.items-list tbody tr').first().addClass('success')
          e.preventDefault()
        return
      if [74, 40].indexOf(e.which) isnt -1 # j or down arrow
        row.removeClass('success').next().addClass('success') if row.next().length
      else if [75, 38].indexOf(e.which) isnt -1 # k or up arrow
        row.removeClass('success').prev().addClass('success') if row.prev().length
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

window.adminiumSelect2Matcher = (term, text, opts) ->
  return true if term is ''
  r = new RegExp(term.split('').join('.*'), 'i')
  return true if text.match(r)

$ -> new Navigation()