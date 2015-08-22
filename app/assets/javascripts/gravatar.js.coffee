class window.Gravatar

  @picture: (email, opts={}) ->
    size = opts.size || 50
    d = opts.default || 'blank'
    "//www.gravatar.com/avatar/#{md5(email)}.jpg?d=#{d}&s=#{size}"

  @profile: (email) ->
    "//www.gravatar.com/#{md5(email)}"

  @emailColumnDetect: ->
    return unless window.hasOwnProperty('columns_hash')
    return 'email' if columns_hash.hasOwnProperty('email')
    for key, value of columns_hash
      return key if (key.indexOf('_email') isnt -1) || (key.indexOf('email_') isnt -1) || (key.indexOf('Email') isnt -1)
    null
  
  @autoDetect: ->
    for div in $('div[data-gravatar-email]')
      src = window.location.protocol + window.location.host + $(div).find('img').attr("src")
      url = @picture($(div).data('gravatar-email'), default: encodeURIComponent(src))
      $(div).find('img').attr('src', url)

  @findAll: =>
    email = @emailColumnDetect()
    return unless email
    columnIndex = $("table.items-list th[data-column-name='#{email}']").index()
    emailCells = $("td:nth-child(#{columnIndex + 1})")
    return if emailCells.length is 0
    $("<th class='gravatar'>").insertAfter $('th.actions')
    $("<td class='gravatar'>").insertAfter $('.items-list tfoot th')
    for elt in emailCells
      here = $(elt).parent('tr').find('.actions')
      value = $(elt).text()
      image = if value.indexOf('@') isnt -1
        "<a href='#{@profile(value)}' target='_blank'><img src='#{@picture(value)}' /></a>"
      else
        ""
      td = $("<td class='gravatar'>#{image}</td>")
      td.insertAfter(here)

$ ->
  Gravatar.findAll()
  Gravatar.autoDetect()
