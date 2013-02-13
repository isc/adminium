class window.Gravatar

  @picture: (email, size) ->
    "http://www.gravatar.com/avatar/#{md5(email)}.jpg?d=blank&s=#{size || 50}"

  @profile: (email) ->
    "http://www.gravatar.com/#{md5(email)}"

  @emailColumnDetect: ->
    return unless window.hasOwnProperty('columns_hash')
    return 'email' if columns_hash.hasOwnProperty('email')
    for key, value of columns_hash
      return key if (key.indexOf('_email') isnt -1) || (key.indexOf('email_') isnt -1) || (key.indexOf('Email') isnt -1)
    null

  @findAll: ->
    email = @emailColumnDetect()
    return unless email
    emailCells = $("td[data-column-name='#{email}']")
    return if emailCells.length is 0
    $("<th>").insertAfter $('th.checkboxes')
    for elt in emailCells
      here = $(elt).parent('tr').find('.click_checkbox')
      value = $(elt).text()
      image = if value.indexOf('@') isnt -1
        "<a href='#{@profile(value)}' target='_blank'><img src='#{@picture(value)}' /></a>"
      else
        ""
      td = $("<td>#{image}</td>")
      td.insertAfter(here)

$ ->
  Gravatar.findAll()