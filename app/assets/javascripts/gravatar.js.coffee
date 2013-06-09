class window.Gravatar

  @picture: (email, size) ->
    "//www.gravatar.com/avatar/#{md5(email)}.jpg?d=blank&s=#{size || 50}"

  @profile: (email) ->
    "//www.gravatar.com/#{md5(email)}"

  @emailColumnDetect: ->
    return unless window.hasOwnProperty('columns_hash')
    return 'email' if columns_hash.hasOwnProperty('email')
    for key, value of columns_hash
      return key if (key.indexOf('_email') isnt -1) || (key.indexOf('email_') isnt -1) || (key.indexOf('Email') isnt -1)
    null

  @findAll: =>
    email = @emailColumnDetect()
    return unless email
    columnIndex = $("table.items-list th[data-column-name='#{email}']").index()
    emailCells = $("td:nth-child(#{columnIndex + 1})")
    return if emailCells.length is 0
    $("<th>").insertAfter $('th.checkboxes')
    $("<td>").insertAfter $('.items-list tfoot th')
    for elt in emailCells
      here = $(elt).parent('tr').find('.click_checkbox')
      value = $(elt).text()
      image = if value.indexOf('@') isnt -1
        "<a href='#{@profile(value)}' target='_blank'><img src='#{@picture(value)}' /></a>"
      else
        ""
      td = $("<td>#{image}</td>")
      td.insertAfter(here)

$ Gravatar.findAll
